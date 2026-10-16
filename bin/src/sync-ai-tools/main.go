package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

// UnifiedServer représente un serveur MCP dans notre modèle canonique interne
type UnifiedServer struct {
	Name        string            `json:"name"`
	Type        string            `json:"type,omitempty"` // "stdio", "http", "local", "remote"
	Command     string            `json:"command,omitempty"`
	Args        []string          `json:"args,omitempty"`
	Env         map[string]string `json:"env,omitempty"`
	URL         string            `json:"url,omitempty"`
	SourceTools []string          `json:"source_tools,omitempty"`
}

func (s UnifiedServer) Equal(o UnifiedServer) bool {
	if s.URL != o.URL {
		return false
	}
	if s.Command != o.Command {
		return false
	}
	if !reflect.DeepEqual(s.Args, o.Args) {
		return false
	}
	if len(s.Env) != len(o.Env) {
		return false
	}
	for k, v := range s.Env {
		if o.Env[k] != v {
			return false
		}
	}
	return true
}

func (s UnifiedServer) DiffDescription(central UnifiedServer) []string {
	var diffs []string
	if s.URL != central.URL {
		diffs = append(diffs, fmt.Sprintf("URL: '%s' (local) vs '%s' (central)", s.URL, central.URL))
	}
	if s.Command != central.Command {
		diffs = append(diffs, fmt.Sprintf("Command: '%s' (local) vs '%s' (central)", s.Command, central.Command))
	}
	if !reflect.DeepEqual(s.Args, central.Args) {
		diffs = append(diffs, fmt.Sprintf("Args: %v (local) vs %v (central)", s.Args, central.Args))
	}
	// Analyse détaillée de l'environnement (clés ajoutées, modifiées, supprimées)
	for k, v := range s.Env {
		if centVal, exists := central.Env[k]; !exists {
			diffs = append(diffs, fmt.Sprintf("+ Env: %s=%s (nouvelle variable)", k, v))
		} else if centVal != v {
			diffs = append(diffs, fmt.Sprintf("~ Env %s: '%s' (local) vs '%s' (central)", k, v, centVal))
		}
	}
	for k, v := range central.Env {
		if _, exists := s.Env[k]; !exists {
			diffs = append(diffs, fmt.Sprintf("- Env: %s=%s (absent en local)", k, v))
		}
	}
	return diffs
}

// 1. Format Canonique Central & VS Code
type CanonicalMCPConfig struct {
	Servers map[string]CanonicalServer `json:"servers"`
}

type CanonicalServer struct {
	Type    string            `json:"type,omitempty"`
	Command string            `json:"command,omitempty"`
	Args    []string          `json:"args,omitempty"`
	Env     map[string]string `json:"env,omitempty"`
	URL     string            `json:"url,omitempty"`
}

// 2. Format Standard MCP (Antigravity & Copilot CLI)
type StandardConfig struct {
	MCPServers map[string]StandardServer `json:"mcpServers"`
}

type StandardServer struct {
	Command string            `json:"command,omitempty"`
	Args    []string          `json:"args,omitempty"`
	Env     map[string]string `json:"env,omitempty"`
	URL     string            `json:"url,omitempty"`
}

// 3. Format OpenCode & Mammouth
type OpenCodeServer struct {
	Type        string            `json:"type,omitempty"`
	Command     []string          `json:"command,omitempty"`
	URL         string            `json:"url,omitempty"`
	Environment map[string]string `json:"environment,omitempty"`
}

type ServerDifference struct {
	ServerName string
	ClientName string
	LocalSrv   UnifiedServer
	CentralSrv UnifiedServer
	Diffs      []string
}

func main() {
	excludeFlag := flag.String("exclude", "", "Liste de serveurs MCP à exclure, séparés par des virgules (ex: -exclude forgejo,datadog)")
	interactiveFlag := flag.Bool("interactive", false, "Mode interactif (-i) : demande confirmation pour les nouveautés, modifications de variables et sens de synchronisation")
	flag.BoolVar(interactiveFlag, "i", false, "Alias court pour -interactive")
	dryRunFlag := flag.Bool("dry-run", false, "Affiche uniquement les différences et actions prévues sans modifier les fichiers")
	workFileFlag := flag.String("work-file", "", "Chemin vers un fichier MCP annexe. Défaut: ~/.local/share/ai-skills/mcp-work.json. Les serveurs de ce fichier sont synchronisés vers tous les clients mais PAS écrits dans le hub central mcp.json. Utile pour des outils spécifiques (ex: bigquery, servicenow) que tu ne veux pas mélanger au hub principal")
	flag.Parse()

	excludedSet := make(map[string]bool)
	if *excludeFlag != "" {
		for _, name := range strings.Split(*excludeFlag, ",") {
			trimmed := strings.TrimSpace(name)
			if trimmed != "" {
				excludedSet[trimmed] = true
			}
		}
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Impossible de déterminer le répertoire HOME : %v\n", err)
		os.Exit(1)
	}

	fmt.Println("=== Synchronisation des MCP & Skills IA ===")
	if len(excludedSet) > 0 {
		var list []string
		for k := range excludedSet {
			list = append(list, k)
		}
		sort.Strings(list)
		fmt.Printf("ℹ️  Serveur(s) exclu(s) : %s\n", strings.Join(list, ", "))
	}
	if *interactiveFlag {
		fmt.Println("🔍 Mode interactif activé")
	}
	if *dryRunFlag {
		fmt.Println("⚠️  Mode DRY-RUN activé (aucune modification ne sera écrite)")
	}

	centralSkillsDir := filepath.Join(homeDir, ".local/share/ai-skills")
	centralMcpPath := filepath.Join(centralSkillsDir, "mcp.json")
	_ = os.MkdirAll(centralSkillsDir, 0755)

	// Fichier annexe : serveurs MCP à synchroniser séparément du hub central
	workFilePath := *workFileFlag
	if workFilePath == "" {
		workFilePath = filepath.Join(centralSkillsDir, "mcp-work.json")
	}
	workServers := make(map[string]UnifiedServer)
	if _, err := os.Stat(workFilePath); err == nil {
		readCanonicalServers(workFilePath, "Fichier annexe", workServers)
		fmt.Printf("ℹ️  Fichier annexe chargé : %s (%d serveur(s))\n", workFilePath, len(workServers))
	} else {
		fmt.Printf("ℹ️  Aucun fichier annexe trouvé (%s) - la sync continue sans serveurs supplémentaires\n", workFilePath)
	}

	// Chemins des 5 clients
	vscodePath := filepath.Join(homeDir, ".config/Code/User/mcp.json")
	geminiPath := filepath.Join(homeDir, ".gemini/config/mcp_config.json")
	copilotPath := filepath.Join(homeDir, ".copilot/mcp-config.json")
	mammouthPath := filepath.Join(homeDir, ".config/mammouth/mammouth.jsonc")
	opencodePath := filepath.Join(homeDir, ".config/opencode/opencode.jsonc")

	// 1. Lire les serveurs du Hub Central
	centralServers := make(map[string]UnifiedServer)
	readCanonicalServers(centralMcpPath, "Hub Central", centralServers)

	// 2. Lire les serveurs de chaque outil client
	clientServers := make(map[string]map[string]UnifiedServer)
	clientServers["VS Code"] = make(map[string]UnifiedServer)
	readCanonicalServers(vscodePath, "VS Code", clientServers["VS Code"])

	clientServers["Antigravity"] = make(map[string]UnifiedServer)
	readStandardServers(geminiPath, "Antigravity", clientServers["Antigravity"])

	clientServers["Copilot CLI"] = make(map[string]UnifiedServer)
	readStandardServers(copilotPath, "Copilot CLI", clientServers["Copilot CLI"])

	clientServers["Mammouth"] = make(map[string]UnifiedServer)
	readOpenCodeServers(mammouthPath, "Mammouth", clientServers["Mammouth"])

	clientServers["OpenCode"] = make(map[string]UnifiedServer)
	readOpenCodeServers(opencodePath, "OpenCode", clientServers["OpenCode"])

	// 3. Détecter :
	//    A. Les NOUVEAUX serveurs (présents dans un client mais pas dans central)
	//    B. Les DIFFÉRENCES DE CONTENU (variables modifiées/ajoutées, arguments changés...)
	newInClients := make(map[string][]string) // serverName -> []clientName
	var contentDiffs []ServerDifference

	allDetected := make(map[string]UnifiedServer)
	for name, s := range centralServers {
		allDetected[name] = s
	}

	// Ajouter les serveurs du fichier annexe (prioritaire sur le hub central)
	for name, s := range workServers {
		allDetected[name] = s
	}

	for clientName, srvs := range clientServers {
		for name, localS := range srvs {
			centS, inCentral := centralServers[name]
			if !inCentral {
				newInClients[name] = append(newInClients[name], clientName)
				mergeServer(allDetected, localS, clientName)
			} else {
				// Le serveur existe : vérifier si son contenu diffère (variables, commande, args)
				if !localS.Equal(centS) {
					diffs := localS.DiffDescription(centS)
					contentDiffs = append(contentDiffs, ServerDifference{
						ServerName: name,
						ClientName: clientName,
						LocalSrv:   localS,
						CentralSrv: centS,
						Diffs:      diffs,
					})
				}
				mergeServer(allDetected, localS, clientName)
			}
		}
	}

	reader := bufio.NewReader(os.Stdin)

	// --- A. Affichage des nouveaux serveurs ---
	if len(newInClients) > 0 {
		fmt.Printf("\n✨ %d nouveau(x) serveur(s) détecté(s) dans vos clients :\n", len(newInClients))
		for name, clients := range newInClients {
			fmt.Printf("   • '%s' (trouvé dans: %s)\n", name, strings.Join(clients, ", "))
		}

		if *interactiveFlag {
			fmt.Print("Souhaitez-vous intégrer ces nouveaux serveurs dans le hub central mcp.json ? [O/n] : ")
			ans, _ := reader.ReadString('\n')
			ans = strings.TrimSpace(strings.ToLower(ans))
			if ans == "n" || ans == "non" {
				for name := range newInClients {
					delete(allDetected, name)
				}
				fmt.Println("⏭️  Nouveaux serveurs ignorés pour cette synchronisation.")
			}
		}
	}

	// --- B. Affichage et gestion des différences de contenu (variables, etc.) ---
	if len(contentDiffs) > 0 {
		fmt.Printf("\n🔄 %d différence(s) de configuration détectée(s) entre vos clients et le hub central :\n", len(contentDiffs))
		for _, d := range contentDiffs {
			fmt.Printf("   ⚙️  Serveur '%s' [Source: %s] :\n", d.ServerName, d.ClientName)
			for _, diffLine := range d.Diffs {
				fmt.Printf("       %s\n", diffLine)
			}
		}

		if *interactiveFlag {
			fmt.Print("\nComment synchroniser ces modifications ?\n [1] Mettre à jour le hub central avec ces nouvelles valeurs (Local -> Central -> Tous)\n [2] Conserver les valeurs du hub central et écraser le client (Central -> Local)\nChoix [1/2] (défaut: 1) : ")
			ans, _ := reader.ReadString('\n')
			ans = strings.TrimSpace(ans)
			if ans == "2" {
				// Revenir aux valeurs de central pour ces serveurs
				for _, d := range contentDiffs {
					allDetected[d.ServerName] = d.CentralSrv
				}
				fmt.Println("🔄 Rétablissement des valeurs du hub central.")
			} else {
				fmt.Println("✓ Nouvelles variables / modifications fusionnées dans le hub central.")
			}
		}
	}

	// Filtrer les exclusions
	finalServers := make(map[string]UnifiedServer)
	for name, s := range allDetected {
		if excludedSet[name] {
			continue
		}
		finalServers[name] = s
	}

	// Confirmation en mode interactif
	if *interactiveFlag {
		fmt.Printf("\n📋 %d serveur(s) seront synchronisés sur l'ensemble des 5 outils :\n", len(finalServers))
		var sortedNames []string
		for name := range finalServers {
			sortedNames = append(sortedNames, name)
		}
		sort.Strings(sortedNames)
		for _, name := range sortedNames {
			s := finalServers[name]
			var envKeys []string
			for k := range s.Env {
				envKeys = append(envKeys, k)
			}
			sort.Strings(envKeys)
			envSummary := ""
			if len(envKeys) > 0 {
				envSummary = fmt.Sprintf(" (envs: %s)", strings.Join(envKeys, ", "))
			}
			fmt.Printf("   ✔ %s%s\n", name, envSummary)
		}

		fmt.Print("\nConfirmer l'écriture et la propagation vers tous les outils ? [O/n] : ")
		ans, _ := reader.ReadString('\n')
		ans = strings.TrimSpace(strings.ToLower(ans))
		if ans == "n" || ans == "non" {
			fmt.Println("Annulé par l'utilisateur.")
			return
		}
	}

	if *dryRunFlag {
		fmt.Println("\n[DRY-RUN] Fin de simulation. Aucun fichier n'a été modifié.")
		return
	}

	// --- Étape B : ÉCRITURE DANS LE HUB CENTRAL ---
	// Les serveurs du fichier annexe ne sont PAS écrits dans le hub central
	centralOnlyServers := make(map[string]UnifiedServer)
	for name, s := range finalServers {
		if _, isWorkServer := workServers[name]; !isWorkServer {
			centralOnlyServers[name] = s
		}
	}
	writeCanonicalConfig(centralMcpPath, centralOnlyServers)
	fmt.Printf("\n[✓] Hub central mis à jour -> %s\n", centralMcpPath)

	// --- Étape C : DISTRIBUTION AUX 5 OUTILS ---
	writeCanonicalConfig(vscodePath, finalServers)
	fmt.Printf("[✓] VS Code mis à jour -> %s\n", vscodePath)

	writeStandardConfig(geminiPath, finalServers)
	fmt.Printf("[✓] Antigravity mis à jour -> %s\n", geminiPath)

	writeStandardConfig(copilotPath, finalServers)
	fmt.Printf("[✓] Copilot CLI mis à jour -> %s\n", copilotPath)

	writeOpenCodeConfig(mammouthPath, finalServers)
	fmt.Printf("[✓] Mammouth CLI mis à jour -> %s\n", mammouthPath)

	writeOpenCodeConfig(opencodePath, finalServers)
	fmt.Printf("[✓] OpenCode mis à jour -> %s\n", opencodePath)

	// --- Étape D : VÉRIFICATION DES SYMLINKS POUR LES SKILLS ---
	skillTargets := []string{
		filepath.Join(homeDir, ".config/opencode/skills"),
		filepath.Join(homeDir, ".gemini/config/skills"),
		filepath.Join(homeDir, ".copilot/skills"),
		filepath.Join(homeDir, ".config/mammouth/skills"),
	}

	for _, target := range skillTargets {
		ensureSymlink(centralSkillsDir, target)
	}
	fmt.Printf("[✓] Skills unifiés et interconnectés -> %s\n", centralSkillsDir)

	fmt.Println("\nSynchronisation terminée avec succès !")
}

// Fusion d'un serveur dans la carte globale
func mergeServer(dest map[string]UnifiedServer, s UnifiedServer, sourceName string) {
	name := strings.TrimSpace(s.Name)
	if name == "" || name == "servers" || name == "inputs" {
		return
	}
	s.Name = name

	existing, found := dest[s.Name]
	if !found {
		s.SourceTools = []string{sourceName}
		dest[s.Name] = s
		return
	}

	if existing.URL == "" && s.URL != "" {
		existing.URL = s.URL
	}
	if existing.Command == "" && s.Command != "" {
		existing.Command = s.Command
	}
	if len(existing.Args) == 0 && len(s.Args) > 0 {
		existing.Args = s.Args
	}
	if existing.Env == nil && s.Env != nil {
		existing.Env = s.Env
	} else if s.Env != nil {
		for k, v := range s.Env {
			existing.Env[k] = v
		}
	}

	hasSource := false
	for _, src := range existing.SourceTools {
		if src == sourceName {
			hasSource = true
			break
		}
	}
	if !hasSource {
		existing.SourceTools = append(existing.SourceTools, sourceName)
	}
	dest[s.Name] = existing
}

// Lecture Format Canonique / VS Code
func readCanonicalServers(path, sourceName string, dest map[string]UnifiedServer) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var cfg CanonicalMCPConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return
	}
	count := 0
	for name, s := range cfg.Servers {
		mergeServer(dest, UnifiedServer{
			Name:    name,
			Type:    s.Type,
			Command: s.Command,
			Args:    s.Args,
			Env:     s.Env,
			URL:     s.URL,
		}, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// Lecture Standard (Antigravity & Copilot)
func readStandardServers(path, sourceName string, dest map[string]UnifiedServer) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var cfg StandardConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return
	}
	count := 0
	for name, s := range cfg.MCPServers {
		mergeServer(dest, UnifiedServer{
			Name:    name,
			Command: s.Command,
			Args:    s.Args,
			Env:     s.Env,
			URL:     s.URL,
		}, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// Lecture OpenCode & Mammouth
func readOpenCodeServers(path, sourceName string, dest map[string]UnifiedServer) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var root map[string]interface{}
	if err := json.Unmarshal(data, &root); err != nil {
		return
	}
	mcpRaw, ok := root["mcp"].(map[string]interface{})
	if !ok {
		return
	}

	count := 0
	for name, srvVal := range mcpRaw {
		sMap, ok := srvVal.(map[string]interface{})
		if !ok {
			continue
		}

		u := UnifiedServer{Name: name}
		if urlVal, ok := sMap["url"].(string); ok {
			u.URL = urlVal
		}

		if cmdSlice, ok := sMap["command"].([]interface{}); ok && len(cmdSlice) > 0 {
			if firstCmd, ok := cmdSlice[0].(string); ok {
				u.Command = firstCmd
			}
			var args []string
			for i := 1; i < len(cmdSlice); i++ {
				if arg, ok := cmdSlice[i].(string); ok {
					args = append(args, arg)
				}
			}
			u.Args = args
		}

		if envRaw, ok := sMap["environment"].(map[string]interface{}); ok {
			envMap := make(map[string]string)
			for k, v := range envRaw {
				if vStr, ok := v.(string); ok {
					if strings.HasPrefix(vStr, "{env:") && strings.HasSuffix(vStr, "}") {
						varName := vStr[5 : len(vStr)-1]
						envMap[k] = fmt.Sprintf("${%s}", varName)
					} else {
						envMap[k] = vStr
					}
				}
			}
			u.Env = envMap
		}

		mergeServer(dest, u, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// Écriture Format Canonique (Central et VS Code)
func writeCanonicalConfig(path string, servers map[string]UnifiedServer) {
	var root map[string]interface{}
	if data, err := os.ReadFile(path); err == nil {
		_ = json.Unmarshal(data, &root)
	}
	if root == nil {
		root = make(map[string]interface{})
	}

	outServers := make(map[string]CanonicalServer)
	for name, s := range servers {
		if s.URL != "" {
			outServers[name] = CanonicalServer{
				Type: "http",
				URL:  s.URL,
			}
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			outServers[name] = CanonicalServer{
				Type:    "stdio",
				Command: cmd,
				Args:    s.Args,
				Env:     s.Env,
			}
		}
	}

	root["servers"] = outServers
	outBytes, _ := json.MarshalIndent(root, "", "  ")
	outBytes = append(outBytes, '\n')
	writeConfigFile(path, outBytes)
}

// Écriture Standard (Antigravity & Copilot CLI)
func writeStandardConfig(path string, servers map[string]UnifiedServer) {
	stdServers := make(map[string]StandardServer)
	for name, s := range servers {
		if s.URL != "" {
			stdServers[name] = StandardServer{
				URL: s.URL,
			}
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			stdServers[name] = StandardServer{
				Command: cmd,
				Args:    s.Args,
				Env:     s.Env,
			}
		}
	}

	stdConfig := StandardConfig{MCPServers: stdServers}
	outBytes, _ := json.MarshalIndent(stdConfig, "", "  ")
	outBytes = append(outBytes, '\n')
	writeConfigFile(path, outBytes)
}

// Écriture OpenCode & Mammouth
func writeOpenCodeConfig(path string, servers map[string]UnifiedServer) {
	var root map[string]interface{}
	if data, err := os.ReadFile(path); err == nil {
		_ = json.Unmarshal(data, &root)
	}
	if root == nil {
		root = make(map[string]interface{})
		root["$schema"] = "https://opencode.ai/config.json"
	}

	ocServers := make(map[string]OpenCodeServer)
	for name, s := range servers {
		if s.URL != "" {
			ocServers[name] = OpenCodeServer{
				Type: "remote",
				URL:  s.URL,
			}
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			fullCmd := append([]string{cmd}, s.Args...)
			osrv := OpenCodeServer{
				Type:    "local",
				Command: fullCmd,
			}
			if len(s.Env) > 0 {
				envMap := make(map[string]string)
				for k, v := range s.Env {
					if strings.HasPrefix(v, "${") && strings.HasSuffix(v, "}") {
						varName := v[2 : len(v)-1]
						envMap[k] = fmt.Sprintf("{env:%s}", varName)
					} else {
						envMap[k] = v
					}
				}
				osrv.Environment = envMap
			}
			ocServers[name] = osrv
		}
	}

	root["mcp"] = ocServers
	outBytes, _ := json.MarshalIndent(root, "", "  ")
	outBytes = append(outBytes, '\n')
	writeConfigFile(path, outBytes)
}

func writeConfigFile(targetPath string, content []byte) {
	_ = os.MkdirAll(filepath.Dir(targetPath), 0755)
	_ = os.WriteFile(targetPath, content, 0644)
}

func ensureSymlink(centralPath, targetPath string) {
	_ = os.MkdirAll(filepath.Dir(targetPath), 0755)

	fi, err := os.Lstat(targetPath)
	if err == nil {
		if fi.Mode()&os.ModeSymlink != 0 {
			linkDest, err := os.Readlink(targetPath)
			if err == nil && linkDest == centralPath {
				return
			}
		}
		_ = os.RemoveAll(targetPath)
	}

	_ = os.Symlink(centralPath, targetPath)
}
