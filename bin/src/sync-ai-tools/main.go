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
	"strconv"
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

// normalizeEnvValue ramène les références d'environnement vers la forme
// canonique interne "${VAR}". Évite les préfixes doubles comme
// "${env:VAR}" (syntaxe VS Code) ou "{env:env:VAR}" après aller-retours.
func normalizeEnvValue(v string) string {
	if strings.HasPrefix(v, "${env:") && strings.HasSuffix(v, "}") {
		return "${" + v[6:len(v)-1] + "}"
	}
	return v
}

func normalizeEnvMap(env map[string]string) map[string]string {
	for k, v := range env {
		env[k] = normalizeEnvValue(v)
	}
	return env
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

// --- Agents personnalisés ---

// agentFormat désigne le format de fichier agent d'un client
type agentFormat int

const (
	agentFormatOpenCode    agentFormat = iota // OpenCode & Mammouth (<name>.md, frontmatter description/mode/model)
	agentFormatCopilot                        // Copilot CLI & VS Code (<name>.agent.md, user-invocable/disable-model-invocation)
	agentFormatAntigravity                    // Antigravity CLI (<name>.md, name/mainAgent/subagent)
)

// UnifiedAgent représente un agent dans notre modèle canonique interne (format OpenCode)
type UnifiedAgent struct {
	Name        string
	Description string
	Mode        string // "primary", "subagent" ou "all"
	Model       string // "provider/model" (significatif uniquement pour le format OpenCode)
	Body        string // instructions / prompt système
	Raw         []byte // octets du fichier hub central (préservés si existant)
	SourceTools []string
}

type AgentDifference struct {
	AgentName   string
	ClientName  string
	LocalFormat agentFormat
	LocalA      UnifiedAgent
	CentralA    UnifiedAgent
	Diffs       []string
}

func main() {
	excludeFlag := flag.String("exclude", "", "Liste de serveurs MCP à exclure, séparés par des virgules (ex: -exclude forgejo,datadog)")
	interactiveFlag := flag.Bool("interactive", false, "Mode interactif (-i) : demande confirmation pour les nouveautés, modifications de variables et sens de synchronisation")
	flag.BoolVar(interactiveFlag, "i", false, "Alias court pour -interactive")
	dryRunFlag := flag.Bool("dry-run", false, "Affiche uniquement les différences et actions prévues sans modifier les fichiers")
	workFileFlag := flag.String("work-file", "", "Chemin vers un fichier MCP annexe. Défaut: ~/.local/share/ai-skills/mcp-work.json. Les serveurs de ce fichier sont synchronisés vers tous les clients mais PAS écrits dans le hub central mcp.json. Utile pour des outils spécifiques (ex: bigquery, servicenow) que tu ne veux pas mélanger au hub principal")
	excludeAgentsFlag := flag.String("exclude-agents", "", "Liste d'agents personnalisés à exclure, séparés par des virgules (ex: -exclude-agents reviewer,traductor)")
	noAgentsFlag := flag.Bool("no-agents", false, "Désactive la synchronisation des agents personnalisés entre les outils")
	agentsDirFlag := flag.String("agents-dir", "", "Chemin du hub central des agents. Défaut: ~/.local/share/ai-agents. Les agents y sont stockés au format canonique OpenCode (.md avec frontmatter), puis convertis pour chaque outil (Copilot CLI/VS Code: .agent.md, Antigravity: agents globaux)")
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

	excludedAgentsSet := make(map[string]bool)
	if *excludeAgentsFlag != "" {
		for _, name := range strings.Split(*excludeAgentsFlag, ",") {
			trimmed := strings.TrimSpace(name)
			if trimmed != "" {
				excludedAgentsSet[trimmed] = true
			}
		}
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Impossible de déterminer le répertoire HOME : %v\n", err)
		os.Exit(1)
	}

	fmt.Println("=== Synchronisation des MCP, Skills & Agents IA ===")
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

	// --- Étape A2 : SYNCHRONISATION DES AGENTS PERSONNALISÉS (simulation en dry-run) ---
	centralAgentsDir := filepath.Join(homeDir, ".local/share/ai-agents")
	if *agentsDirFlag != "" {
		centralAgentsDir = *agentsDirFlag
	}
	if *dryRunFlag {
		if !*noAgentsFlag {
			syncAgents(centralAgentsDir, excludedAgentsSet, *interactiveFlag, true, homeDir, reader)
		}
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
	writeCanonicalConfig(centralMcpPath, centralOnlyServers, false)
	fmt.Printf("\n[✓] Hub central mis à jour -> %s\n", centralMcpPath)

	// --- Étape C : DISTRIBUTION AUX 5 OUTILS ---
	writeCanonicalConfig(vscodePath, finalServers, true)
	fmt.Printf("[✓] VS Code mis à jour -> %s\n", vscodePath)

	writeStandardConfig(geminiPath, finalServers)
	fmt.Printf("[✓] Antigravity mis à jour -> %s\n", geminiPath)

	writeStandardConfig(copilotPath, finalServers)
	fmt.Printf("[✓] Copilot CLI mis à jour -> %s\n", copilotPath)

	writeOpenCodeConfig(mammouthPath, finalServers)
	fmt.Printf("[✓] Mammouth CLI mis à jour -> %s\n", mammouthPath)

	writeOpenCodeConfig(opencodePath, finalServers)
	fmt.Printf("[✓] OpenCode mis à jour -> %s\n", opencodePath)

	// --- Étape C2 : SYNCHRONISATION DES AGENTS PERSONNALISÉS ---
	if !*noAgentsFlag {
		syncAgents(centralAgentsDir, excludedAgentsSet, *interactiveFlag, false, homeDir, reader)
	} else {
		fmt.Println("\nℹ️  Synchronisation des agents désactivée (-no-agents)")
	}

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
			Env:     normalizeEnvMap(s.Env),
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
			Env:     normalizeEnvMap(s.Env),
			URL:     s.URL,
		}, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// stripJSONC supprime les commentaires // et /* */ d'un fichier JSONC afin de
// le rendre lisible par encoding/json (OpenCode et Mammouth utilisent .jsonc).
func stripJSONC(data []byte) []byte {
	s := string(data)
	var out strings.Builder
	inString, escaped := false, false
	for i := 0; i < len(s); {
		c := s[i]
		if inString {
			out.WriteByte(c)
			switch {
			case escaped:
				escaped = false
			case c == '\\':
				escaped = true
			case c == '"':
				inString = false
			}
			i++
			continue
		}
		switch {
		case c == '"':
			inString = true
			out.WriteByte(c)
			i++
		case c == '/' && i+1 < len(s) && s[i+1] == '/':
			for i < len(s) && s[i] != '\n' {
				i++
			}
		case c == '/' && i+1 < len(s) && s[i+1] == '*':
			i += 2
			for i+1 < len(s) && !(s[i] == '*' && s[i+1] == '/') {
				i++
			}
			if i+1 < len(s) {
				i += 2
			}
		default:
			out.WriteByte(c)
			i++
		}
	}
	return []byte(out.String())
}

// Lecture OpenCode & Mammouth
func readOpenCodeServers(path, sourceName string, dest map[string]UnifiedServer) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var root map[string]interface{}
	if err := json.Unmarshal(stripJSONC(data), &root); err != nil {
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
			u.Env = normalizeEnvMap(envMap)
		}

		mergeServer(dest, u, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// Écriture Format Canonique (Central et VS Code)
// asEnvSyntax=true convertit les références "${VAR}" en "${env:VAR}"
// (syntaxe d'interpolation exigée par mcp.json dans VS Code).
func writeCanonicalConfig(path string, servers map[string]UnifiedServer, asEnvSyntax bool) {
	var root map[string]interface{}
	if data, err := os.ReadFile(path); err == nil {
		_ = json.Unmarshal(stripJSONC(data), &root)
	}
	if root == nil {
		root = make(map[string]interface{})
	}

	outServers := make(map[string]CanonicalServer)
	for name, s := range servers {
		env := s.Env
		if asEnvSyntax && len(env) > 0 {
			env = make(map[string]string, len(env))
			for k, v := range s.Env {
				if strings.HasPrefix(v, "${") && strings.HasSuffix(v, "}") {
					varName := v[2 : len(v)-1]
					env[k] = fmt.Sprintf("${env:%s}", varName)
				} else {
					env[k] = v
				}
			}
		}
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
				Env:     env,
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
		_ = json.Unmarshal(stripJSONC(data), &root)
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

// ---------- Synchronisation des agents personnalisés ----------

// syncAgents synchronise les agents entre le hub central (~/.local/share/ai-agents)
// et les clients : OpenCode, Mammouth, Copilot CLI / VS Code (~/.copilot/agents)
// et Antigravity CLI (~/.gemini/config/agents).
func syncAgents(centralDir string, excluded map[string]bool, interactive, dryRun bool, homeDir string, reader *bufio.Reader) {
	fmt.Printf("\n=== Synchronisation des agents personnalisés ===\n")
	if len(excluded) > 0 {
		var list []string
		for k := range excluded {
			list = append(list, k)
		}
		sort.Strings(list)
		fmt.Printf("ℹ️  Agent(s) exclu(s) : %s\n", strings.Join(list, ", "))
	}

	_ = os.MkdirAll(centralDir, 0755)

	clients := []struct {
		Name   string
		Path   string
		Format agentFormat
	}{
		{"OpenCode", filepath.Join(homeDir, ".config/opencode/agents"), agentFormatOpenCode},
		{"Mammouth", filepath.Join(homeDir, ".config/mammouth/agents"), agentFormatOpenCode},
		{"Copilot CLI / VS Code", filepath.Join(homeDir, ".copilot/agents"), agentFormatCopilot},
		{"Antigravity", filepath.Join(homeDir, ".gemini/config/agents"), agentFormatAntigravity},
	}

	// 1. Lire le hub central (source de vérité canonique)
	centralAgents := make(map[string]UnifiedAgent)
	readAgentsDir(centralDir, agentFormatOpenCode, "Hub Central agents", centralAgents)

	// 2. Détecter nouveaux agents et différences côté clients
	newInClients := make(map[string][]string) // agentName -> []clientName
	var contentDiffs []AgentDifference
	finalAgents := make(map[string]UnifiedAgent)
	hubDirty := make(map[string]bool)   // hub file doit être (ré)écrit
	needRender := make(map[string]bool) // agent importé d'un format non canonique -> rendu canonique requis
	for name, a := range centralAgents {
		finalAgents[name] = a
	}

	for _, c := range clients {
		ags := make(map[string]UnifiedAgent)
		readAgentsDir(c.Path, c.Format, c.Name, ags)
		for name, a := range ags {
			centA, inCentral := centralAgents[name]
			if !inCentral {
				newInClients[name] = append(newInClients[name], c.Name)
				finalAgents[name] = a
				hubDirty[name] = true
				needRender[name] = c.Format != agentFormatOpenCode
			} else {
				compareModel := c.Format == agentFormatOpenCode
				if diffs := agentDiffLines(a, centA, compareModel); len(diffs) > 0 {
					contentDiffs = append(contentDiffs, AgentDifference{
						AgentName:   name,
						ClientName:  c.Name,
						LocalFormat: c.Format,
						LocalA:      a,
						CentralA:    centA,
						Diffs:       diffs,
					})
				}
			}
		}
	}

	// 3a. Nouveaux agents : import dans le hub
	if len(newInClients) > 0 {
		var names []string
		for name := range newInClients {
			names = append(names, name)
		}
		sort.Strings(names)
		fmt.Printf("\n✨ %d nouvel(aux) agent(s) personnalisé(s) détecté(s) dans vos clients :\n", len(names))
		for _, name := range names {
			fmt.Printf("   • '%s' (trouvé dans: %s)\n", name, strings.Join(newInClients[name], ", "))
		}
		if interactive {
			fmt.Print("Souhaitez-vous intégrer ces nouveaux agents dans le hub central et les propager aux autres outils ? [O/n] : ")
			ans, _ := reader.ReadString('\n')
			ans = strings.TrimSpace(strings.ToLower(ans))
			if ans == "n" || ans == "non" {
				for name := range newInClients {
					delete(finalAgents, name)
					delete(hubDirty, name)
					delete(needRender, name)
				}
				fmt.Println("⏭️  Nouveaux agents ignorés pour cette synchronisation.")
			}
		}
	}

	// 3b. Différences de contenu entre un client et le hub
	if len(contentDiffs) > 0 {
		fmt.Printf("\n🔄 %d différence(s) d'agent(s) détectée(s) entre vos clients et le hub central :\n", len(contentDiffs))
		for _, d := range contentDiffs {
			fmt.Printf("   ⚙️  Agent '%s' [Source: %s] :\n", d.AgentName, d.ClientName)
			for _, diffLine := range d.Diffs {
				fmt.Printf("       %s\n", diffLine)
			}
		}
		if interactive {
			fmt.Print("\nComment synchroniser ces agents ?\n [1] Mettre à jour le hub central depuis les clients (Local -> Central -> Tous)\n [2] Conserver le hub central et écraser les clients (Central -> Local)\nChoix [1/2] (défaut: 2) : ")
			ans, _ := reader.ReadString('\n')
			ans = strings.TrimSpace(ans)
			if ans == "1" {
				for _, d := range contentDiffs {
					finalAgents[d.AgentName] = d.LocalA
					needRender[d.AgentName] = d.LocalFormat != agentFormatOpenCode
					hubDirty[d.AgentName] = true
				}
				fmt.Println("✓ Modifications locales fusionnées dans le hub central des agents.")
			} else {
				fmt.Println("🔄 Rétablissement des valeurs du hub central pour ces agents.")
			}
		} else {
			fmt.Println("ℹ️  Mode non-interactif : le hub central est prioritaire, les clients divergents seront écrasés.")
		}
	}

	// 4. Filtrer les exclusions
	plan := make(map[string]UnifiedAgent)
	for name, a := range finalAgents {
		if excluded[name] {
			continue
		}
		plan[name] = a
	}

	var sortedNames []string
	for name := range plan {
		sortedNames = append(sortedNames, name)
	}
	sort.Strings(sortedNames)

	if interactive {
		fmt.Printf("\n📋 %d agent(s) seront synchronisés sur l'ensemble des outils (OpenCode, Mammouth, Copilot CLI / VS Code, Antigravity) :\n", len(sortedNames))
		for _, name := range sortedNames {
			a := plan[name]
			fmt.Printf("   ✔ %s (mode: %s)\n", name, a.Mode)
		}
		fmt.Print("\nConfirmer l'écriture des agents vers tous les outils ? [O/n] : ")
		ans, _ := reader.ReadString('\n')
		ans = strings.TrimSpace(strings.ToLower(ans))
		if ans == "n" || ans == "non" {
			fmt.Println("⏭️  Synchronisation des agents annulée par l'utilisateur.")
			return
		}
	}

	if dryRun {
		fmt.Printf("\n[DRY-RUN] %d agent(s) seraient synchronisés : %s\n", len(sortedNames), strings.Join(sortedNames, ", "))
		return
	}

	// 5. Écriture
	for _, name := range sortedNames {
		a := plan[name]
		// Copie conforme : on préserve les octets d'origine (frontmatter enrichi :
		// permissions, color, etc.) sauf si l'agent provient d'un autre format.
		hubBytes := a.Raw
		if needRender[name] || len(hubBytes) == 0 {
			hubBytes = renderCanonicalAgent(a)
		}
		if hubDirty[name] {
			writeConfigFile(filepath.Join(centralDir, name+".md"), hubBytes)
		}

		// OpenCode & Mammouth : copie conforme du hub (format identique)
		for _, c := range clients {
			if c.Format != agentFormatOpenCode {
				continue
			}
			writeConfigFile(filepath.Join(c.Path, name+".md"), hubBytes)
		}

		// Copilot CLI / VS Code : conversion .agent.md
		for _, c := range clients {
			if c.Format != agentFormatCopilot {
				continue
			}
			writeConfigFile(filepath.Join(c.Path, name+".agent.md"), renderCopilotAgent(a))
		}

		// Antigravity : conversion subagent markdown global
		for _, c := range clients {
			if c.Format != agentFormatAntigravity {
				continue
			}
			writeConfigFile(filepath.Join(c.Path, name+".md"), renderAntigravityAgent(a))
		}
	}

	fmt.Printf("[✓] %d agent(s) synchronisé(s) -> hub %s + OpenCode, Mammouth, Copilot CLI / VS Code, Antigravity\n", len(sortedNames), centralDir)
}

// readAgentsDir lit un répertoire d'agents au format donné.
func readAgentsDir(dir string, format agentFormat, sourceName string, dest map[string]UnifiedAgent) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return
	}
	count := 0
	for _, e := range entries {
		if e.IsDir() {
			// Sous-répertoire <name>/agent.md (Antigravity & OpenCode)
			if format != agentFormatAntigravity && format != agentFormatOpenCode {
				continue
			}
			if data, err := os.ReadFile(filepath.Join(dir, e.Name(), "agent.md")); err == nil {
				if addAgentFromFile(dest, e.Name(), data, format) {
					count++
				}
			}
			continue
		}
		fn := e.Name()
		if strings.HasPrefix(fn, ".") || !strings.HasSuffix(fn, ".md") {
			continue
		}
		name := strings.TrimSuffix(strings.TrimSuffix(fn, ".md"), ".agent")
		if name == "" || strings.Contains(name, "/") {
			continue
		}
		data, err := os.ReadFile(filepath.Join(dir, fn))
		if err != nil {
			continue
		}
		if addAgentFromFile(dest, name, data, format) {
			count++
		}
	}
	fmt.Printf("• %d agent(s) lu(s) depuis %s\n", count, sourceName)
}

// addAgentFromFile parse un fichier agent et l'ajoute au modèle canonique.
func addAgentFromFile(dest map[string]UnifiedAgent, name string, data []byte, format agentFormat) bool {
	fm, body := parseFrontMatter(data)
	a := UnifiedAgent{
		Name:        name,
		Description: fmString(fm, "description"),
		Model:       fmString(fm, "model"),
		Body:        strings.TrimSpace(body),
		Raw:         data,
	}
	if strings.EqualFold(a.Model, "inherit") {
		a.Model = ""
	}

	switch format {
	case agentFormatOpenCode:
		a.Mode = fmString(fm, "mode")
		if a.Mode == "" {
			a.Mode = "all"
		}
	case agentFormatCopilot:
		a.Model = "" // pas d'équivalent fiable entre fournisseurs de modèles
		userInvocable := fmBool(fm, "user-invocable", true)
		disableModel := fmBool(fm, "disable-model-invocation", false)
		switch {
		case userInvocable && disableModel:
			a.Mode = "primary"
		case !userInvocable && !disableModel:
			a.Mode = "subagent"
		default:
			a.Mode = "all"
		}
	case agentFormatAntigravity:
		a.Model = ""
		mainAgent := fmBool(fm, "mainAgent", true)
		subagent := fmBool(fm, "subagent", true)
		switch {
		case mainAgent && !subagent:
			a.Mode = "primary"
		case !mainAgent && subagent:
			a.Mode = "subagent"
		default:
			a.Mode = "all"
		}
	}

	if strings.TrimSpace(a.Description) == "" && a.Body == "" {
		return false
	}
	dest[name] = a
	return true
}

// agentDiffLines compare un agent client au hub central (modèle canonique).
func agentDiffLines(local, central UnifiedAgent, compareModel bool) []string {
	var diffs []string
	if strings.TrimSpace(local.Description) != strings.TrimSpace(central.Description) {
		diffs = append(diffs, fmt.Sprintf("~ Description: '%s' (local) vs '%s' (central)", truncateLine(local.Description, 60), truncateLine(central.Description, 60)))
	}
	if local.Mode != central.Mode {
		diffs = append(diffs, fmt.Sprintf("~ Mode: '%s' (local) vs '%s' (central)", local.Mode, central.Mode))
	}
	if compareModel && local.Model != central.Model {
		diffs = append(diffs, fmt.Sprintf("~ Model: '%s' (local) vs '%s' (central)", local.Model, central.Model))
	}
	if local.Body != central.Body {
		diffs = append(diffs, "~ Instructions (corps du fichier): différentes")
	}
	return diffs
}

// renderCanonicalAgent produit le format canonique OpenCode/Mammouth/hub.
func renderCanonicalAgent(a UnifiedAgent) []byte {
	var b strings.Builder
	b.WriteString("---\n")
	if a.Description != "" {
		b.WriteString("description: " + yamlQuote(a.Description) + "\n")
	}
	mode := a.Mode
	if mode == "" {
		mode = "all"
	}
	b.WriteString("mode: " + mode + "\n")
	if a.Model != "" {
		b.WriteString("model: " + a.Model + "\n")
	}
	b.WriteString("---\n\n")
	b.WriteString(a.Body)
	b.WriteString("\n")
	return []byte(b.String())
}

// renderCopilotAgent produit le format Copilot CLI / VS Code (.agent.md).
func renderCopilotAgent(a UnifiedAgent) []byte {
	var b strings.Builder
	b.WriteString("---\n")
	if a.Description != "" {
		b.WriteString("description: " + yamlQuote(a.Description) + "\n")
	}
	switch a.Mode {
	case "primary":
		b.WriteString("user-invocable: true\n")
		b.WriteString("disable-model-invocation: true\n")
	case "subagent":
		b.WriteString("user-invocable: false\n")
	}
	b.WriteString("---\n\n")
	b.WriteString(a.Body)
	b.WriteString("\n")
	return []byte(b.String())
}

// renderAntigravityAgent produit le format Antigravity CLI (~/.gemini/config/agents).
func renderAntigravityAgent(a UnifiedAgent) []byte {
	var b strings.Builder
	b.WriteString("---\n")
	b.WriteString("name: " + a.Name + "\n")
	if a.Description != "" {
		b.WriteString("description: " + yamlQuote(a.Description) + "\n")
	}
	switch a.Mode {
	case "primary":
		b.WriteString("mainAgent: true\n")
		b.WriteString("subagent: false\n")
	case "subagent":
		b.WriteString("mainAgent: false\n")
		b.WriteString("subagent: true\n")
	default:
		b.WriteString("mainAgent: true\n")
		b.WriteString("subagent: true\n")
	}
	b.WriteString("model: inherit\n")
	b.WriteString("---\n\n")
	b.WriteString(a.Body)
	b.WriteString("\n")
	return []byte(b.String())
}

func truncateLine(s string, n int) string {
	s = strings.Join(strings.Fields(s), " ")
	r := []rune(s)
	if len(r) > n {
		return string(r[:n]) + "…"
	}
	return s
}

func yamlQuote(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	return "\"" + s + "\""
}

// --- Mini-parseur YAML (sous-ensemble suffisant pour les frontmatter d'agents) ---

// parseFrontMatter sépare le bloc YAML d'en-tête (--- ... ---) du corps markdown.
func parseFrontMatter(data []byte) (map[string]any, string) {
	s := strings.ReplaceAll(string(data), "\r\n", "\n")
	if !strings.HasPrefix(s, "---\n") {
		return nil, s
	}
	lines := strings.Split(s[4:], "\n")
	end := -1
	for j, l := range lines {
		t := strings.TrimSpace(l)
		if t == "---" || t == "..." {
			end = j
			break
		}
	}
	if end < 0 {
		return nil, s
	}
	fm := parseYAMLFrontmatter(strings.Join(lines[:end], "\n"))
	body := strings.Join(lines[end+1:], "\n")
	return fm, body
}

// parseYAMLFrontmatter interprète un sous-ensemble YAML : scalaires, booléens,
// listes inline [a, b], listes en bloc (- item), scalaires en bloc (>-, |, |-).
func parseYAMLFrontmatter(text string) map[string]any {
	out := make(map[string]any)
	lines := strings.Split(text, "\n")
	for i := 0; i < len(lines); {
		line := lines[i]
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			i++
			continue
		}
		// Les lignes indentées orphelines (contenu imbriqué non supporté) sont ignorées
		if line[0] == ' ' || line[0] == '\t' {
			i++
			continue
		}
		key, val, found := strings.Cut(line, ":")
		if !found {
			i++
			continue
		}
		key = strings.TrimSpace(key)
		val = strings.TrimSpace(val)
		i++

		switch {
		case val == "":
			// Liste en bloc (ou valeur vide) : consommer les lignes indentées suivantes
			var list []string
			for i < len(lines) {
				l := lines[i]
				if strings.TrimSpace(l) == "" {
					i++
					continue
				}
				if l[0] != ' ' && l[0] != '\t' {
					break
				}
				list = append(list, strings.TrimSpace(l))
				i++
			}
			out[key] = list
		case val == ">-" || val == ">" || val == ">+" || val == "|" || val == "|-" || val == "|+":
			// Scalaire en bloc : joindre les lignes indentées suivantes
			var parts []string
			for i < len(lines) {
				l := lines[i]
				if strings.TrimSpace(l) == "" {
					parts = append(parts, "")
					i++
					continue
				}
				if l[0] != ' ' && l[0] != '\t' {
					break
				}
				parts = append(parts, strings.TrimLeft(l, " \t"))
				i++
			}
			for len(parts) > 0 && parts[len(parts)-1] == "" {
				parts = parts[:len(parts)-1]
			}
			sep := " "
			if strings.HasPrefix(val, "|") {
				sep = "\n"
			}
			out[key] = strings.TrimSpace(strings.Join(parts, sep))
		case strings.HasPrefix(val, "["):
			inner := strings.TrimSuffix(strings.TrimPrefix(val, "["), "]")
			var list []string
			for _, p := range strings.Split(inner, ",") {
				p = strings.TrimSpace(p)
				if p != "" {
					list = append(list, strings.Trim(p, "\"'"))
				}
			}
			out[key] = list
		default:
			out[key] = unquoteScalar(val)
		}
	}
	return out
}

func unquoteScalar(v string) any {
	switch v {
	case "true":
		return true
	case "false":
		return false
	}
	if len(v) >= 2 {
		if v[0] == '"' && v[len(v)-1] == '"' {
			s := v[1 : len(v)-1]
			s = strings.ReplaceAll(s, "\\\"", "\"")
			s = strings.ReplaceAll(s, "\\\\", "\\")
			return s
		}
		if v[0] == '\'' && v[len(v)-1] == '\'' {
			return strings.ReplaceAll(v[1:len(v)-1], "''", "'")
		}
	}
	return v
}

func fmString(fm map[string]any, key string) string {
	if fm == nil {
		return ""
	}
	switch v := fm[key].(type) {
	case string:
		return v
	case bool:
		return fmt.Sprintf("%v", v)
	case []string:
		return strings.Join(v, " ")
	}
	return ""
}

func fmBool(fm map[string]any, key string, def bool) bool {
	if fm == nil {
		return def
	}
	switch v := fm[key].(type) {
	case bool:
		return v
	case string:
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return def
}
