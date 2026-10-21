package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// OAuthConfig représente la configuration OAuth d'un serveur MCP distant
type OAuthConfig struct {
	ClientID     string `json:"clientId,omitempty"`
	ClientSecret string `json:"clientSecret,omitempty"`
	Scope        string `json:"scope,omitempty"`
	CallbackPort int    `json:"callbackPort,omitempty"`
	RedirectURI  string `json:"redirectUri,omitempty"`
}

func (o *OAuthConfig) IsEmpty() bool {
	if o == nil {
		return true
	}
	return o.ClientID == "" && o.ClientSecret == "" && o.Scope == "" && o.CallbackPort == 0 && o.RedirectURI == ""
}

func (o *OAuthConfig) Clone() *OAuthConfig {
	if o.IsEmpty() {
		return nil
	}
	cp := *o
	return &cp
}

func oauthEqual(a, b *OAuthConfig) bool {
	if a.IsEmpty() && b.IsEmpty() {
		return true
	}
	if a.IsEmpty() != b.IsEmpty() {
		return false
	}
	return a.ClientID == b.ClientID &&
		a.ClientSecret == b.ClientSecret &&
		a.Scope == b.Scope &&
		a.CallbackPort == b.CallbackPort &&
		a.RedirectURI == b.RedirectURI
}

// UnifiedServer représente un serveur MCP dans notre modèle canonique interne
type UnifiedServer struct {
	Name        string            `json:"name"`
	Type        string            `json:"type,omitempty"` // "stdio", "http", "local", "remote"
	Command     string            `json:"command,omitempty"`
	Args        []string          `json:"args,omitempty"`
	Env         map[string]string `json:"env,omitempty"`
	URL         string            `json:"url,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	OAuth       *OAuthConfig      `json:"oauth,omitempty"`
	SourceTools []string          `json:"source_tools,omitempty"`
}

// SyncExcludeConfig représente le fichier d'exclusions (~/.local/share/ai-skills/sync-exclude.json)
type SyncExcludeConfig struct {
	Patterns []string `json:"patterns,omitempty"`
	MCP      []string `json:"mcp,omitempty"`
	Agents   []string `json:"agents,omitempty"`
	Skills   []string `json:"skills,omitempty"`
}

// Expressions régulières pour normaliser les variables d'environnement y compris
// lorsqu'elles sont intégrées dans une chaîne (ex: "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}").
var (
	reDollarEnvRef = regexp.MustCompile(`\$\{(?:env:)+([A-Za-z0-9_]+)\}`)
	reBraceEnvRef  = regexp.MustCompile(`\{(?:env:)+([A-Za-z0-9_]+)\}`)
	reCanonicalRef = regexp.MustCompile(`\$\{([A-Za-z0-9_]+)\}`)
)

// normalizeEnvValue ramène les références d'environnement vers la forme
// canonique interne "${VAR}". Évite les préfixes doubles comme
// "${env:VAR}" (syntaxe VS Code) ou "{env:env:VAR}" après aller-retours.
func normalizeEnvValue(v string) string {
	for {
		next := reDollarEnvRef.ReplaceAllString(v, "${$1}")
		next = reBraceEnvRef.ReplaceAllString(next, "${$1}")
		if next == v {
			break
		}
		v = next
	}
	return v
}

func toVSCodeEnvValue(v string) string {
	v = normalizeEnvValue(v)
	return reCanonicalRef.ReplaceAllString(v, "${env:$1}")
}

func toOpenCodeEnvValue(v string) string {
	v = normalizeEnvValue(v)
	return reCanonicalRef.ReplaceAllString(v, "{env:$1}")
}

func normalizeEnvMap(env map[string]string) map[string]string {
	if len(env) == 0 {
		return nil
	}
	out := make(map[string]string, len(env))
	for k, v := range env {
		out[k] = normalizeEnvValue(v)
	}
	return out
}

func convertEnvMap(env map[string]string, conv func(string) string) map[string]string {
	if len(env) == 0 {
		return nil
	}
	out := make(map[string]string, len(env))
	for k, v := range env {
		out[k] = conv(v)
	}
	return out
}

func normalizeOAuth(o *OAuthConfig) *OAuthConfig {
	if o.IsEmpty() {
		return nil
	}
	cp := o.Clone()
	cp.ClientID = normalizeEnvValue(cp.ClientID)
	cp.ClientSecret = normalizeEnvValue(cp.ClientSecret)
	return cp
}

func convertOAuth(o *OAuthConfig, conv func(string) string) *OAuthConfig {
	if o.IsEmpty() {
		return nil
	}
	cp := o.Clone()
	cp.ClientID = conv(cp.ClientID)
	cp.ClientSecret = conv(cp.ClientSecret)
	return cp
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
	if len(s.Headers) != len(o.Headers) {
		return false
	}
	for k, v := range s.Headers {
		if o.Headers[k] != v {
			return false
		}
	}
	if !oauthEqual(s.OAuth, o.OAuth) {
		return false
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
	// Headers
	for k, v := range s.Headers {
		if centVal, exists := central.Headers[k]; !exists {
			diffs = append(diffs, fmt.Sprintf("+ Header: %s=%s", k, v))
		} else if centVal != v {
			diffs = append(diffs, fmt.Sprintf("~ Header %s: '%s' (local) vs '%s' (central)", k, v, centVal))
		}
	}
	for k, v := range central.Headers {
		if _, exists := s.Headers[k]; !exists {
			diffs = append(diffs, fmt.Sprintf("- Header: %s=%s (absent en local)", k, v))
		}
	}
	// OAuth
	if !oauthEqual(s.OAuth, central.OAuth) {
		diffs = append(diffs, fmt.Sprintf("~ OAuth: %+v (local) vs %+v (central)", s.OAuth, central.OAuth))
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
	Headers map[string]string `json:"headers,omitempty"`
	OAuth   *OAuthConfig      `json:"oauth,omitempty"`
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
	Headers map[string]string `json:"headers,omitempty"`
}

// 3. Format OpenCode & Mammouth
type OpenCodeServer struct {
	Type        string            `json:"type,omitempty"`
	Command     []string          `json:"command,omitempty"`
	URL         string            `json:"url,omitempty"`
	Environment map[string]string `json:"environment,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	OAuth       *OAuthConfig      `json:"oauth,omitempty"`
	Enabled     *bool             `json:"enabled,omitempty"`
}

type ServerDifference struct {
	ServerName string
	ClientName string
	LocalSrv   UnifiedServer
	CentralSrv UnifiedServer
	IsWork     bool
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

	// Déclaration des sous-agents que cet agent peut invoquer :
	//   Subagents = ["*"]        -> tous les sous-agents disponibles
	//   Subagents = ["a", "b"]   -> liste restreinte (roster)
	//   NoSubagents = true       -> interdiction explicite (roster vide)
	// Les deux restent à leur valeur zéro si l'agent ne déclare rien.
	// Conversion : OpenCode/Mammouth -> règles permissions "subagent",
	// Copilot CLI/VS Code et Antigravity -> champ frontmatter "agents".
	Subagents   []string
	NoSubagents bool
}

type AgentDifference struct {
	AgentName   string
	ClientName  string
	LocalFormat agentFormat
	LocalA      UnifiedAgent
	CentralA    UnifiedAgent
	Diffs       []string
}

// parseCSVSet découpe une liste séparée par des virgules en ensemble normalisé (minuscules)
func parseCSVSet(csv string, dest map[string]bool) {
	if csv == "" {
		return
	}
	for _, item := range strings.Split(csv, ",") {
		trimmed := strings.ToLower(strings.TrimSpace(item))
		if trimmed != "" {
			dest[trimmed] = true
		}
	}
}

func addSliceToSet(items []string, dest map[string]bool) {
	for _, item := range items {
		trimmed := strings.ToLower(strings.TrimSpace(item))
		if trimmed != "" {
			dest[trimmed] = true
		}
	}
}

// containsTokenIgnoreCase vérifie si `pat` (en minuscules) apparaît dans `text`
// en tant que mot/jeton (non entouré de lettres ASCII a-z), afin que "adeo"
// matche "ADEO", "adeo-cli", "adeo.cloud", mais pas le mot anglais "tradeoff".
func containsTokenIgnoreCase(text, pat string) bool {
	if pat == "" || text == "" {
		return false
	}
	lower := strings.ToLower(text)
	offset := 0
	for {
		idx := strings.Index(lower[offset:], pat)
		if idx < 0 {
			return false
		}
		start := offset + idx
		end := start + len(pat)
		prevAlpha := start > 0 && lower[start-1] >= 'a' && lower[start-1] <= 'z'
		nextAlpha := end < len(lower) && lower[end] >= 'a' && lower[end] <= 'z'
		if !prevAlpha && !nextAlpha {
			return true
		}
		offset = start + 1
	}
}

// matchesExclusion vérifie si un élément (MCP, skill ou agent) est exclu soit par
// son nom exact dans exactSet, soit parce que son nom ou ses métadonnées (extraTexts)
// contiennent l'un des motifs de patterns (ex: "adeo", "lmfr").
func matchesExclusion(name string, exactSet map[string]bool, patterns []string, extraTexts ...string) bool {
	lowerName := strings.ToLower(strings.TrimSpace(name))
	if exactSet[lowerName] {
		return true
	}
	for pat := range exactSet {
		if strings.ContainsAny(pat, "*?") {
			if ok, _ := filepath.Match(pat, lowerName); ok {
				return true
			}
		}
	}
	for _, rawPat := range patterns {
		pat := strings.ToLower(strings.TrimSpace(rawPat))
		if pat == "" {
			continue
		}
		if strings.Contains(lowerName, pat) {
			return true
		}
		for _, txt := range extraTexts {
			if txt != "" && containsTokenIgnoreCase(txt, pat) {
				return true
			}
		}
	}
	return false
}

func loadExcludeConfig(path string) SyncExcludeConfig {
	var cfg SyncExcludeConfig
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg
	}
	_ = json.Unmarshal(stripJSONC(data), &cfg)
	return cfg
}

func main() {
	excludeFlag := flag.String("exclude", "", "Liste de serveurs MCP supplémentaires à exclure, séparés par des virgules")
	excludeAgentsFlag := flag.String("exclude-agents", "", "Liste d'agents supplémentaires à exclure, séparés par des virgules")
	excludeSkillsFlag := flag.String("exclude-skills", "", "Liste de skills supplémentaires à exclure, séparés par des virgules")
	excludePatternsFlag := flag.String("exclude-patterns", "adeo,lmfr", "Motifs implicites (sous-chaînes insensibles à la casse) à exclure pour les MCP, skills et agents")
	excludeFileFlag := flag.String("exclude-file", "", "Chemin vers le fichier d'exclusions JSON. Défaut: ~/.local/share/ai-skills/sync-exclude.json (et mcp-work.json)")
	interactiveFlag := flag.Bool("interactive", false, "Mode interactif (-i) : demande confirmation pour les nouveautés, modifications de variables et sens de synchronisation")
	flag.BoolVar(interactiveFlag, "i", false, "Alias court pour -interactive")
	dryRunFlag := flag.Bool("dry-run", false, "Affiche uniquement les différences et actions prévues sans modifier les fichiers")
	workFileFlag := flag.String("work-file", "", "Chemin vers un fichier MCP annexe. Défaut: ~/.local/share/ai-skills/mcp-work.json. Les serveurs de ce fichier sont synchronisés vers tous les clients mais PAS écrits dans le hub central mcp.json. Utile pour des outils spécifiques (ex: bigquery, servicenow) que tu ne veux pas mélanger au hub principal")
	noAgentsFlag := flag.Bool("no-agents", false, "Désactive la synchronisation des agents personnalisés entre les outils")
	noSkillsFlag := flag.Bool("no-skills", false, "Désactive la synchronisation des skills entre les outils")
	agentsDirFlag := flag.String("agents-dir", "", "Chemin du hub central des agents. Défaut: ~/.local/share/ai-agents. Les agents y sont stockés au format canonique OpenCode (.md avec frontmatter), puis convertis pour chaque outil (Copilot CLI/VS Code: .agent.md, Antigravity: agents globaux)")
	flag.Parse()

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Impossible de déterminer le répertoire HOME : %v\n", err)
		os.Exit(1)
	}

	centralSkillsDir := filepath.Join(homeDir, ".local/share/ai-skills")
	centralMcpPath := filepath.Join(centralSkillsDir, "mcp.json")
	_ = os.MkdirAll(centralSkillsDir, 0755)

	// Chargement implicite des exclusions depuis sync-exclude.json ET mcp-work.json
	excludeFilePath := *excludeFileFlag
	if excludeFilePath == "" {
		excludeFilePath = filepath.Join(centralSkillsDir, "sync-exclude.json")
	}
	workFilePathForExclude := *workFileFlag
	if workFilePathForExclude == "" {
		workFilePathForExclude = filepath.Join(centralSkillsDir, "mcp-work.json")
	}
	excludeCfg := loadExcludeConfig(excludeFilePath)
	workExcludeCfg := loadExcludeConfig(workFilePathForExclude)

	excludedMCPSet := map[string]bool{
		"bigquery":            true,
		"servicenow":          true,
		"servicenow-mcp-prod": true,
		"github-mcp":          true,
	}
	addSliceToSet(excludeCfg.MCP, excludedMCPSet)
	addSliceToSet(workExcludeCfg.MCP, excludedMCPSet)
	parseCSVSet(*excludeFlag, excludedMCPSet)

	excludedAgentsSet := make(map[string]bool)
	addSliceToSet(excludeCfg.Agents, excludedAgentsSet)
	addSliceToSet(workExcludeCfg.Agents, excludedAgentsSet)
	parseCSVSet(*excludeAgentsFlag, excludedAgentsSet)

	excludedSkillsSet := make(map[string]bool)
	addSliceToSet(excludeCfg.Skills, excludedSkillsSet)
	addSliceToSet(workExcludeCfg.Skills, excludedSkillsSet)
	parseCSVSet(*excludeSkillsFlag, excludedSkillsSet)

	patternSet := map[string]bool{
		"adeo": true,
		"lmfr": true,
	}
	addSliceToSet(excludeCfg.Patterns, patternSet)
	addSliceToSet(workExcludeCfg.Patterns, patternSet)
	parseCSVSet(*excludePatternsFlag, patternSet)
	var excludePatterns []string
	for p := range patternSet {
		excludePatterns = append(excludePatterns, p)
	}
	sort.Strings(excludePatterns)

	fmt.Println("=== Synchronisation des MCP, Skills & Agents IA ===")
	if _, err := os.Stat(excludeFilePath); err == nil {
		fmt.Printf("ℹ️  Fichier d'exclusions chargé : %s\n", excludeFilePath)
	}
	if len(excludePatterns) > 0 {
		fmt.Printf("ℹ️  Motif(s) global(aux) d'exclusion : %s\n", strings.Join(excludePatterns, ", "))
	}
	if len(excludedMCPSet) > 0 {
		var list []string
		for k := range excludedMCPSet {
			list = append(list, k)
		}
		sort.Strings(list)
		fmt.Printf("ℹ️  Serveur(s) MCP exclu(s) du hub central : %s\n", strings.Join(list, ", "))
	}
	if *interactiveFlag {
		fmt.Println("🔍 Mode interactif activé")
	}
	if *dryRunFlag {
		fmt.Println("⚠️  Mode DRY-RUN activé (aucune modification ne sera écrite)")
	}

	// Fichier annexe : serveurs MCP à synchroniser séparément du hub central (ex: bigquery, servicenow-mcp-prod)
	workFilePath := *workFileFlag
	if workFilePath == "" {
		workFilePath = filepath.Join(centralSkillsDir, "mcp-work.json")
	}
	workServers := make(map[string]UnifiedServer)
	hasWorkFile := false
	if _, err := os.Stat(workFilePath); err == nil {
		hasWorkFile = true
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
	opencodeJsonPath := filepath.Join(homeDir, ".config/opencode/opencode.json")
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
	// OpenCode charge opencode.json puis opencode.jsonc (qui écrase opencode.json).
	// On lit opencode.json en premier pour récupérer oauth/headers éventuels, puis opencode.jsonc.
	readOpenCodeServers(opencodeJsonPath, "OpenCode (opencode.json)", clientServers["OpenCode"])
	readOpenCodeServers(opencodePath, "OpenCode", clientServers["OpenCode"])

	// 3. Détecter :
	//    A. Les NOUVEAUX serveurs (présents dans un client mais ni dans central ni dans workFile, et non exclus)
	//    B. Les DIFFÉRENCES DE CONTENU (variables modifiées/ajoutées, arguments changés...)
	newInClients := make(map[string][]string) // serverName -> []clientName
	var contentDiffs []ServerDifference

	allDetected := make(map[string]UnifiedServer)
	for name, s := range centralServers {
		if matchesExclusion(name, excludedMCPSet, excludePatterns, s.URL, s.Command) {
			continue
		}
		allDetected[name] = s
	}

	// Ajouter les serveurs du fichier annexe (prioritaire sur le hub central, synchronisés vers les clients mais jamais écrits dans mcp.json)
	for name, s := range workServers {
		allDetected[name] = s
	}

	for clientName, srvs := range clientServers {
		for name, localS := range srvs {
			workS, inWork := workServers[name]
			centS, inCentral := centralServers[name]

			if inWork {
				// Ce serveur appartient au fichier d'exclusion/annexe (mcp-work.json)
				localMerged := enrichServerFromBase(localS, workS)
				if !localMerged.Equal(workS) {
					diffs := localMerged.DiffDescription(workS)
					contentDiffs = append(contentDiffs, ServerDifference{
						ServerName: name,
						ClientName: clientName,
						LocalSrv:   localMerged,
						CentralSrv: workS,
						IsWork:     true,
						Diffs:      diffs,
					})
				}
				continue
			}

			// Si le serveur est exclu (par liste mcp ou motif adeo/lmfr) et pas dans le hub central, on l'ignore
			if matchesExclusion(name, excludedMCPSet, excludePatterns, localS.URL, localS.Command) {
				continue
			}

			if !inCentral {
				newInClients[name] = append(newInClients[name], clientName)
				mergeServer(allDetected, localS, clientName)
			} else {
				// Enrichir localS avec OAuth/Headers de centS si le client (ex: Antigravity/Copilot) ne supporte pas ces champs
				localMerged := enrichServerFromBase(localS, centS)
				if !localMerged.Equal(centS) {
					diffs := localMerged.DiffDescription(centS)
					contentDiffs = append(contentDiffs, ServerDifference{
						ServerName: name,
						ClientName: clientName,
						LocalSrv:   localMerged,
						CentralSrv: centS,
						IsWork:     false,
						Diffs:      diffs,
					})
				}
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
	workUpdated := false
	if len(contentDiffs) > 0 {
		fmt.Printf("\n🔄 %d différence(s) de configuration détectée(s) entre vos clients et le hub :\n", len(contentDiffs))
		for _, d := range contentDiffs {
			hubLabel := "mcp.json"
			if d.IsWork {
				hubLabel = "mcp-work.json"
			}
			fmt.Printf("   ⚙️  Serveur '%s' [Source: %s vs %s] :\n", d.ServerName, d.ClientName, hubLabel)
			for _, diffLine := range d.Diffs {
				fmt.Printf("       %s\n", diffLine)
			}
		}

		if *interactiveFlag {
			fmt.Print("\nComment synchroniser ces modifications ?\n [1] Mettre à jour le hub avec ces nouvelles valeurs (Local -> Hub -> Tous)\n [2] Conserver les valeurs du hub et écraser le client (Hub -> Local)\nChoix [1/2] (défaut: 2) : ")
			ans, _ := reader.ReadString('\n')
			ans = strings.TrimSpace(ans)
			if ans == "1" {
				for _, d := range contentDiffs {
					allDetected[d.ServerName] = d.LocalSrv
					if d.IsWork {
						workServers[d.ServerName] = d.LocalSrv
						workUpdated = true
					}
				}
				fmt.Println("✓ Nouvelles variables / modifications fusionnées dans le hub.")
			} else {
				for _, d := range contentDiffs {
					allDetected[d.ServerName] = d.CentralSrv
				}
				fmt.Println("🔄 Rétablissement des valeurs du hub.")
			}
		} else {
			fmt.Println("ℹ️  Mode non-interactif : le hub est prioritaire, les clients divergents seront alignés.")
		}
	}

	//Construire la carte finale des serveurs à distribuer aux clients :
	// - tous les serveurs du hub central (non exclus)
	// - tous les serveurs de mcp-work.json (sauf si explicitement passés dans -exclude en ligne de commande)
	cliExcludedMCP := make(map[string]bool)
	parseCSVSet(*excludeFlag, cliExcludedMCP)

	finalServers := make(map[string]UnifiedServer)
	for name, s := range allDetected {
		if cliExcludedMCP[strings.ToLower(name)] {
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
			if _, isWork := workServers[name]; isWork {
				envSummary += " [work/exclu de mcp.json]"
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

	// --- Étape A2 : SYNCHRONISATION DES AGENTS PERSONNALISÉS & SKILLS (simulation en dry-run) ---
	centralAgentsDir := filepath.Join(homeDir, ".local/share/ai-agents")
	if *agentsDirFlag != "" {
		centralAgentsDir = *agentsDirFlag
	}
	if *dryRunFlag {
		if !*noAgentsFlag {
			syncAgents(centralAgentsDir, excludedAgentsSet, excludePatterns, *interactiveFlag, true, homeDir, reader)
		}
		if !*noSkillsFlag {
			syncSkills(centralSkillsDir, excludedSkillsSet, excludePatterns, true, homeDir)
		}
		fmt.Println("\n[DRY-RUN] Fin de simulation. Aucun fichier n'a été modifié.")
		return
	}

	// --- Étape B : ÉCRITURE DANS LE HUB CENTRAL ---
	// Les serveurs du fichier annexe (mcp-work.json) et les serveurs exclus ne sont JAMAIS écrits dans mcp.json
	centralOnlyServers := make(map[string]UnifiedServer)
	for name, s := range finalServers {
		if _, isWorkServer := workServers[name]; isWorkServer {
			continue
		}
		if matchesExclusion(name, excludedMCPSet, excludePatterns, s.URL, s.Command) {
			continue
		}
		centralOnlyServers[name] = s
	}
	writeCanonicalConfig(centralMcpPath, centralOnlyServers, false, nil, nil)
	fmt.Printf("\n[✓] Hub central mis à jour -> %s\n", centralMcpPath)

	if hasWorkFile && workUpdated {
		writeCanonicalConfig(workFilePath, workServers, false, nil, nil)
		fmt.Printf("[✓] Fichier annexe mis à jour -> %s\n", workFilePath)
	}

	// --- Étape C : DISTRIBUTION AUX 5 OUTILS ---
	writeCanonicalConfig(vscodePath, finalServers, true, excludedMCPSet, excludePatterns)
	fmt.Printf("[✓] VS Code mis à jour -> %s\n", vscodePath)

	writeStandardConfig(geminiPath, finalServers, excludedMCPSet, excludePatterns)
	fmt.Printf("[✓] Antigravity mis à jour -> %s\n", geminiPath)

	writeStandardConfig(copilotPath, finalServers, excludedMCPSet, excludePatterns)
	fmt.Printf("[✓] Copilot CLI mis à jour -> %s\n", copilotPath)

	writeOpenCodeConfig(mammouthPath, finalServers, excludedMCPSet, excludePatterns)
	fmt.Printf("[✓] Mammouth CLI mis à jour -> %s\n", mammouthPath)

	writeOpenCodeConfig(opencodePath, finalServers, excludedMCPSet, excludePatterns)
	fmt.Printf("[✓] OpenCode mis à jour -> %s\n", opencodePath)

	// --- Étape C2 : SYNCHRONISATION DES AGENTS PERSONNALISÉS ---
	if !*noAgentsFlag {
		syncAgents(centralAgentsDir, excludedAgentsSet, excludePatterns, *interactiveFlag, false, homeDir, reader)
	} else {
		fmt.Println("\nℹ️  Synchronisation des agents désactivée (-no-agents)")
	}

	// --- Étape D : SYNCHRONISATION DES SKILLS & SYMLINKS ---
	if !*noSkillsFlag {
		syncSkills(centralSkillsDir, excludedSkillsSet, excludePatterns, false, homeDir)
	} else {
		fmt.Println("\nℹ️  Synchronisation des skills désactivée (-no-skills)")
	}

	fmt.Println("\nSynchronisation terminée avec succès !")
}

// enrichServerFromBase préserve OAuth/Headers de la base centrale lorsque le client
// (ex: format Standard Antigravity/Copilot) ne stocke pas ces champs.
func enrichServerFromBase(local, base UnifiedServer) UnifiedServer {
	// Si le type de serveur a changé (ex: local stdio vs remote http), ne pas mélanger
	if (local.URL != "") != (base.URL != "") {
		return local
	}
	if local.URL != "" {
		if local.OAuth.IsEmpty() && !base.OAuth.IsEmpty() {
			local.OAuth = base.OAuth.Clone()
		}
		if len(local.Headers) == 0 && len(base.Headers) > 0 {
			local.Headers = make(map[string]string, len(base.Headers))
			for k, v := range base.Headers {
				local.Headers[k] = v
			}
		}
	}
	return local
}

// Fusion d'un serveur dans la carte globale (en gardant URL et Command mutuellement exclusifs)
func mergeServer(dest map[string]UnifiedServer, s UnifiedServer, sourceName string) {
	name := strings.TrimSpace(s.Name)
	if name == "" || name == "servers" || name == "inputs" {
		return
	}
	s.Name = name
	if s.URL != "" {
		s.Command = ""
		s.Args = nil
		s.Env = nil
	} else {
		s.Headers = nil
		s.OAuth = nil
	}

	existing, found := dest[s.Name]
	if !found {
		s.SourceTools = []string{sourceName}
		dest[s.Name] = s
		return
	}

	// Ne fusionner les champs complémentaires que si les deux entrées sont du même type (remote vs stdio)
	if (existing.URL != "") == (s.URL != "") {
		if existing.URL != "" {
			if existing.OAuth.IsEmpty() && !s.OAuth.IsEmpty() {
				existing.OAuth = s.OAuth.Clone()
			}
			if len(existing.Headers) == 0 && len(s.Headers) > 0 {
				existing.Headers = s.Headers
			} else if len(s.Headers) > 0 {
				for k, v := range s.Headers {
					if _, ok := existing.Headers[k]; !ok {
						existing.Headers[k] = v
					}
				}
			}
		} else {
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
					if _, ok := existing.Env[k]; !ok {
						existing.Env[k] = v
					}
				}
			}
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
	if err := json.Unmarshal(stripJSONC(data), &cfg); err != nil {
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
			Headers: normalizeEnvMap(s.Headers),
			OAuth:   normalizeOAuth(s.OAuth),
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
	if err := json.Unmarshal(stripJSONC(data), &cfg); err != nil {
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
			Headers: normalizeEnvMap(s.Headers),
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
					envMap[k] = normalizeEnvValue(vStr)
				}
			}
			u.Env = normalizeEnvMap(envMap)
		}

		if hdrRaw, ok := sMap["headers"].(map[string]interface{}); ok {
			hdrMap := make(map[string]string)
			for k, v := range hdrRaw {
				if vStr, ok := v.(string); ok {
					hdrMap[k] = normalizeEnvValue(vStr)
				}
			}
			u.Headers = normalizeEnvMap(hdrMap)
		}

		if oauthRaw, ok := sMap["oauth"].(map[string]interface{}); ok {
			var oc OAuthConfig
			if b, err := json.Marshal(oauthRaw); err == nil {
				_ = json.Unmarshal(b, &oc)
			}
			u.OAuth = normalizeOAuth(&oc)
		}

		// Si un serveur existe déjà dans dest (ex: lu depuis opencode.json avant opencode.jsonc),
		// on enrichit u avec OAuth/Headers de l'existant avant d'écraser si même type.
		if prev, exists := dest[name]; exists {
			u = enrichServerFromBase(u, prev)
			delete(dest, name)
		}

		mergeServer(dest, u, sourceName)
		count++
	}
	fmt.Printf("• %d serveur(s) lu(s) depuis %s\n", count, sourceName)
}

// Écriture Format Canonique (Central et VS Code)
// asEnvSyntax=true convertit les références "${VAR}" en "${env:VAR}"
// (syntaxe d'interpolation exigée par mcp.json dans VS Code).
func writeCanonicalConfig(path string, servers map[string]UnifiedServer, asEnvSyntax bool, excludedMCP map[string]bool, excludePatterns []string) {
	var root map[string]interface{}
	if data, err := os.ReadFile(path); err == nil {
		_ = json.Unmarshal(stripJSONC(data), &root)
	}
	if root == nil {
		root = make(map[string]interface{})
	}

	outServers := make(map[string]CanonicalServer)
	// Préserver les serveurs exclus déjà présents dans le fichier client
	if excludedMCP != nil || len(excludePatterns) > 0 {
		if existingRaw, ok := root["servers"].(map[string]interface{}); ok {
			for name, rawVal := range existingRaw {
				if _, inFinal := servers[name]; !inFinal && matchesExclusion(name, excludedMCP, excludePatterns) {
					var cs CanonicalServer
					if b, err := json.Marshal(rawVal); err == nil && json.Unmarshal(b, &cs) == nil {
						outServers[name] = cs
					}
				}
			}
		}
	}

	valConv := normalizeEnvValue
	if asEnvSyntax {
		valConv = toVSCodeEnvValue
	}

	for name, s := range servers {
		if s.URL != "" {
			cs := CanonicalServer{
				Type:    "http",
				URL:     s.URL,
				Headers: convertEnvMap(s.Headers, valConv),
			}
			// Dans mcp.json central (asEnvSyntax=false), on sauvegarde aussi OAuth pour ne pas le perdre
			if !asEnvSyntax {
				cs.OAuth = convertOAuth(s.OAuth, valConv)
			}
			outServers[name] = cs
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			outServers[name] = CanonicalServer{
				Type:    "stdio",
				Command: cmd,
				Args:    s.Args,
				Env:     convertEnvMap(s.Env, valConv),
			}
		}
	}

	root["servers"] = outServers
	outBytes, _ := json.MarshalIndent(root, "", "  ")
	outBytes = append(outBytes, '\n')
	writeConfigFile(path, outBytes)
}

// Écriture Standard (Antigravity & Copilot CLI)
func writeStandardConfig(path string, servers map[string]UnifiedServer, excludedMCP map[string]bool, excludePatterns []string) {
	stdServers := make(map[string]StandardServer)
	if excludedMCP != nil || len(excludePatterns) > 0 {
		if data, err := os.ReadFile(path); err == nil {
			var existing StandardConfig
			if json.Unmarshal(stripJSONC(data), &existing) == nil {
				for name, srv := range existing.MCPServers {
					if _, inFinal := servers[name]; !inFinal && matchesExclusion(name, excludedMCP, excludePatterns, srv.URL, srv.Command) {
						stdServers[name] = srv
					}
				}
			}
		}
	}

	for name, s := range servers {
		if s.URL != "" {
			stdServers[name] = StandardServer{
				URL:     s.URL,
				Headers: normalizeEnvMap(s.Headers),
			}
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			stdServers[name] = StandardServer{
				Command: cmd,
				Args:    s.Args,
				Env:     normalizeEnvMap(s.Env),
			}
		}
	}

	stdConfig := StandardConfig{MCPServers: stdServers}
	outBytes, _ := json.MarshalIndent(stdConfig, "", "  ")
	outBytes = append(outBytes, '\n')
	writeConfigFile(path, outBytes)
}

// Écriture OpenCode & Mammouth
func writeOpenCodeConfig(path string, servers map[string]UnifiedServer, excludedMCP map[string]bool, excludePatterns []string) {
	var root map[string]interface{}
	if data, err := os.ReadFile(path); err == nil {
		_ = json.Unmarshal(stripJSONC(data), &root)
	}
	if root == nil {
		root = make(map[string]interface{})
		root["$schema"] = "https://opencode.ai/config.json"
	}

	ocServers := make(map[string]OpenCodeServer)
	if excludedMCP != nil || len(excludePatterns) > 0 {
		if existingRaw, ok := root["mcp"].(map[string]interface{}); ok {
			for name, rawVal := range existingRaw {
				if _, inFinal := servers[name]; !inFinal && matchesExclusion(name, excludedMCP, excludePatterns) {
					var osrv OpenCodeServer
					if b, err := json.Marshal(rawVal); err == nil && json.Unmarshal(b, &osrv) == nil {
						ocServers[name] = osrv
					}
				}
			}
		}
	}

	for name, s := range servers {
		if s.URL != "" {
			ocServers[name] = OpenCodeServer{
				Type:    "remote",
				URL:     s.URL,
				Headers: convertEnvMap(s.Headers, toOpenCodeEnvValue),
				OAuth:   convertOAuth(s.OAuth, toOpenCodeEnvValue),
			}
		} else {
			cmd := s.Command
			if cmd == "" {
				cmd = "npx"
			}
			fullCmd := append([]string{cmd}, s.Args...)
			osrv := OpenCodeServer{
				Type:        "local",
				Command:     fullCmd,
				Environment: convertEnvMap(s.Env, toOpenCodeEnvValue),
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

// ---------- Synchronisation des skills avec mécanisme d'exclusion ----------

// syncSkills assure les symlinks des outils vers ~/.local/share/ai-skills et
// synchronise les répertoires de skills individuels (~/.agents/skills, ~/.claude/skills)
// en excluant tout skill figurant dans excludedSkills ou correspondant à excludePatterns (ex: adeo, lmfr).
func syncSkills(centralSkillsDir string, excludedSkills map[string]bool, excludePatterns []string, dryRun bool, homeDir string) {
	fmt.Printf("\n=== Synchronisation des skills ===\n")

	skillTargets := []string{
		filepath.Join(homeDir, ".config/opencode/skills"),
		filepath.Join(homeDir, ".gemini/config/skills"),
		filepath.Join(homeDir, ".copilot/skills"),
		filepath.Join(homeDir, ".config/mammouth/skills"),
	}

	if !dryRun {
		for _, target := range skillTargets {
			ensureSymlink(centralSkillsDir, target)
		}
	}

	// Scanner les répertoires de skills par entrée (~/.agents/skills, ~/.claude/skills)
	perSkillDirs := []struct {
		Name string
		Path string
	}{
		{"Agents (.agents/skills)", filepath.Join(homeDir, ".agents/skills")},
		{"Claude (.claude/skills)", filepath.Join(homeDir, ".claude/skills")},
	}

	excludedFound := make(map[string]bool)
	repairedLinks := 0
	legacyPrefix := filepath.Join(homeDir, ".local/share/agent-skills-sources") + "/"

	for _, dirInfo := range perSkillDirs {
		entries, err := os.ReadDir(dirInfo.Path)
		if err != nil {
			continue
		}
		for _, e := range entries {
			name := e.Name()
			if strings.HasPrefix(name, ".") {
				continue
			}
			fullPath := filepath.Join(dirInfo.Path, name)
			linkTarget, _ := os.Readlink(fullPath)
			skillMdPath := filepath.Join(fullPath, "SKILL.md")
			skillContent, _ := os.ReadFile(skillMdPath)

			if matchesExclusion(name, excludedSkills, excludePatterns, linkTarget, string(skillContent)) {
				excludedFound[name] = true
				continue
			}

			// Réparer les anciens symlinks pointant vers ~/.local/share/agent-skills-sources/...
			if linkTarget != "" && strings.HasPrefix(linkTarget, legacyPrefix) {
				rel := strings.TrimPrefix(linkTarget, legacyPrefix)
				newTarget := filepath.Join(centralSkillsDir, rel)
				if _, err := os.Stat(newTarget); err == nil {
					if !dryRun {
						_ = os.Remove(fullPath)
						_ = os.Symlink(newTarget, fullPath)
					}
					repairedLinks++
				}
			}
		}
	}

	// Vérifier également les skills dans le hub central pour signaler ceux qui seraient exclus
	if entries, err := os.ReadDir(centralSkillsDir); err == nil {
		for _, e := range entries {
			if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
				continue
			}
			name := e.Name()
			skillMdPath := filepath.Join(centralSkillsDir, name, "SKILL.md")
			skillContent, _ := os.ReadFile(skillMdPath)
			if matchesExclusion(name, excludedSkills, excludePatterns, string(skillContent)) {
				excludedFound[name] = true
			}
		}
	}

	if len(excludedFound) > 0 {
		var list []string
		for k := range excludedFound {
			list = append(list, k)
		}
		sort.Strings(list)
		fmt.Printf("⏭️  %d skill(s) exclu(s) ignoré(s) (non importés dans le hub) : %s\n", len(list), strings.Join(list, ", "))
	}
	if repairedLinks > 0 {
		if dryRun {
			fmt.Printf("[DRY-RUN] %d symlink(s) de skills obsolètes seraient réparés vers %s\n", repairedLinks, centralSkillsDir)
		} else {
			fmt.Printf("[✓] %d symlink(s) de skills réparés vers %s\n", repairedLinks, centralSkillsDir)
		}
	}
	if !dryRun {
		fmt.Printf("[✓] Skills unifiés et interconnectés -> %s\n", centralSkillsDir)
	}
}

// ---------- Synchronisation des agents personnalisés ----------

// isAgentExcluded vérifie si un agent doit être exclu par son nom, sa description,
// son corps markdown, ou les motifs globaux (ex: "adeo", "lmfr").
func isAgentExcluded(a UnifiedAgent, excluded map[string]bool, patterns []string) bool {
	return matchesExclusion(a.Name, excluded, patterns, a.Description, a.Body)
}

// syncAgents synchronise les agents entre le hub central (~/.local/share/ai-agents)
// et les clients : OpenCode, Mammouth, Copilot CLI / VS Code (~/.copilot/agents)
// et Antigravity CLI (~/.gemini/config/agents).
func syncAgents(centralDir string, excluded map[string]bool, excludePatterns []string, interactive, dryRun bool, homeDir string, reader *bufio.Reader) {
	fmt.Printf("\n=== Synchronisation des agents personnalisés ===\n")

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

	// Lire tous les clients en mémoire
	clientAgentMaps := make([]map[string]UnifiedAgent, len(clients))
	for idx, c := range clients {
		ags := make(map[string]UnifiedAgent)
		readAgentsDir(c.Path, c.Format, c.Name, ags)
		clientAgentMaps[idx] = ags
	}

	// Passe 1 & 2 d'exclusion :
	// - Passe 1 : tout agent dont le nom, la description ou le contenu correspond à `excluded` ou `excludePatterns` (ex: adeo, lmfr)
	// - Passe 2 : tout sous-agent déclaré dans le roster `Subagents` d'un agent principal exclu (ex: agent-data-lmfr -> bigquery, dbt, kestra...)
	effectiveExcluded := make(map[string]bool)
	for k, v := range excluded {
		if v {
			effectiveExcluded[strings.ToLower(k)] = true
		}
	}
	excludedDetected := make(map[string]bool)

	checkAndMark := func(a UnifiedAgent) {
		if isAgentExcluded(a, effectiveExcluded, excludePatterns) {
			lower := strings.ToLower(a.Name)
			effectiveExcluded[lower] = true
			excludedDetected[a.Name] = true
			for _, sub := range a.Subagents {
				if sub != "*" && sub != "" {
					effectiveExcluded[strings.ToLower(sub)] = true
					excludedDetected[sub] = true
				}
			}
		}
	}

	for _, a := range centralAgents {
		checkAndMark(a)
	}
	for _, ags := range clientAgentMaps {
		for _, a := range ags {
			checkAndMark(a)
		}
	}
	// Marquer aussi les agents clients qui ont été exclus via le roster d'un agent principal
	for _, ags := range clientAgentMaps {
		for name := range ags {
			if effectiveExcluded[strings.ToLower(name)] {
				excludedDetected[name] = true
			}
		}
	}

	if len(excludedDetected) > 0 {
		var list []string
		for k := range excludedDetected {
			list = append(list, k)
		}
		sort.Strings(list)
		fmt.Printf("⏭️  %d agent(s) exclu(s) ignoré(s) : %s\n", len(list), strings.Join(list, ", "))
	}

	// 2. Détecter nouveaux agents et différences côté clients (hors agents exclus)
	newInClients := make(map[string][]string) // agentName -> []clientName
	var contentDiffs []AgentDifference
	finalAgents := make(map[string]UnifiedAgent)
	hubDirty := make(map[string]bool)   // hub file doit être (ré)écrit
	needRender := make(map[string]bool) // agent importé d'un format non canonique -> rendu canonique requis
	for name, a := range centralAgents {
		if effectiveExcluded[strings.ToLower(name)] {
			continue
		}
		finalAgents[name] = a
	}

	for idx, c := range clients {
		ags := clientAgentMaps[idx]
		for name, a := range ags {
			if effectiveExcluded[strings.ToLower(name)] {
				continue
			}
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
		if effectiveExcluded[strings.ToLower(name)] {
			continue
		}
		plan[name] = a
	}

	var sortedNames []string
	for name := range plan {
		sortedNames = append(sortedNames, name)
	}
	sort.Strings(sortedNames)

	if interactive && len(sortedNames) > 0 {
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
		roster, all, deny := parseSubagentRules(fm)
		switch {
		case all:
			a.Subagents = []string{"*"}
		case len(roster) > 0:
			a.Subagents = roster
		case deny:
			a.NoSubagents = true
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
		if list, present := fmSubagentList(fm); present {
			applySubagentList(&a, list)
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
		if list, present := fmSubagentList(fm); present {
			applySubagentList(&a, list)
		}
	}

	if strings.TrimSpace(a.Description) == "" && a.Body == "" {
		return false
	}
	dest[name] = a
	return true
}

// applySubagentList normalise un roster lu en frontmatter ("agents: [...]").
func applySubagentList(a *UnifiedAgent, list []string) {
	var cleaned []string
	star := false
	for _, s := range list {
		if s == "*" {
			star = true
			continue
		}
		cleaned = append(cleaned, s)
	}
	switch {
	case star:
		a.Subagents = []string{"*"}
		a.NoSubagents = false
	case len(cleaned) > 0:
		sort.Strings(cleaned)
		a.Subagents = cleaned
		a.NoSubagents = false
	default:
		a.Subagents = nil
		a.NoSubagents = true
	}
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
	if !subagentDeclEqual(local, central) {
		diffs = append(diffs, fmt.Sprintf("~ Sous-agents: [%s] (local) vs [%s] (central)", subagentDeclLabel(local), subagentDeclLabel(central)))
	}
	if local.Body != central.Body {
		diffs = append(diffs, "~ Instructions (corps du fichier): différentes")
	}
	return diffs
}

func subagentDeclEqual(a, b UnifiedAgent) bool {
	if a.NoSubagents != b.NoSubagents {
		return false
	}
	if len(a.Subagents) != len(b.Subagents) {
		return false
	}
	for i := range a.Subagents {
		if a.Subagents[i] != b.Subagents[i] {
			return false
		}
	}
	return true
}

func subagentDeclLabel(a UnifiedAgent) string {
	switch {
	case a.NoSubagents:
		return "aucun"
	case len(a.Subagents) == 1 && a.Subagents[0] == "*":
		return "tous"
	default:
		return strings.Join(a.Subagents, ", ")
	}
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
	// Roster de sous-agents -> règles permissions "subagent" (dernière règle
	// gagnante : on part d'un deny "*" puis on autorise chaque sous-agent).
	if len(a.Subagents) > 0 || a.NoSubagents {
		b.WriteString("permissions:\n")
		if len(a.Subagents) == 1 && a.Subagents[0] == "*" {
			b.WriteString("  - action: subagent\n    resource: \"*\"\n    effect: allow\n")
		} else {
			b.WriteString("  - action: subagent\n    resource: \"*\"\n    effect: deny\n")
			for _, s := range a.Subagents {
				fmt.Fprintf(&b, "  - action: subagent\n    resource: %s\n    effect: allow\n", yamlQuote(s))
			}
		}
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
	writeSubagentsField(&b, a)
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
	writeSubagentsField(&b, a)
	b.WriteString("---\n\n")
	b.WriteString(a.Body)
	b.WriteString("\n")
	return []byte(b.String())
}

// writeSubagentsField émet le champ frontmatter "agents" (Copilot / Antigravity).
func writeSubagentsField(b *strings.Builder, a UnifiedAgent) {
	switch {
	case len(a.Subagents) > 0:
		quoted := make([]string, 0, len(a.Subagents))
		for _, s := range a.Subagents {
			quoted = append(quoted, yamlQuote(s))
		}
		fmt.Fprintf(b, "agents: [%s]\n", strings.Join(quoted, ", "))
	case a.NoSubagents:
		b.WriteString("agents: []\n")
	}
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
			var raw []string
			for i < len(lines) {
				l := lines[i]
				if strings.TrimSpace(l) == "" {
					i++
					continue
				}
				if l[0] != ' ' && l[0] != '\t' {
					break
				}
				raw = append(raw, strings.TrimSpace(l))
				i++
			}
			out[key] = parseBlockItems(raw)
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

// parseBlockItems transforme les lignes indentées d'une liste en bloc YAML en
// éléments []any : scalaires ("- reviewer") ou mini-cartes enchaînées
// ("- action: subagent" puis "resource: ..." / "effect: allow").
func parseBlockItems(raw []string) []any {
	var items []any
	var cur map[string]any
	flush := func() {
		if cur != nil {
			items = append(items, cur)
			cur = nil
		}
	}
	for _, l := range raw {
		if l == "-" || strings.HasPrefix(l, "- ") {
			flush()
			rest := strings.TrimSpace(strings.TrimPrefix(l, "-"))
			if k, v, found := strings.Cut(rest, ":"); found {
				k = strings.TrimSpace(k)
				if k != "" && !strings.Contains(k, " ") {
					cur = map[string]any{k: unquoteScalar(strings.TrimSpace(v))}
					continue
				}
			}
			if rest != "" {
				items = append(items, unquoteScalar(rest))
			}
			continue
		}
		if k, v, found := strings.Cut(l, ":"); found && cur != nil {
			cur[strings.TrimSpace(k)] = unquoteScalar(strings.TrimSpace(v))
		}
	}
	flush()
	return items
}

// fmItems renvoie une liste de frontmatter sous forme []any + un booléen
// indiquant si la clé était présente (permet de distinguer absent vs vide).
func fmItems(fm map[string]any, key string) ([]any, bool) {
	if fm == nil {
		return nil, false
	}
	v, present := fm[key]
	if !present {
		return nil, false
	}
	switch t := v.(type) {
	case []string:
		out := make([]any, 0, len(t))
		for _, s := range t {
			out = append(out, s)
		}
		return out, true
	case []any:
		return t, true
	}
	return nil, true
}

// fmSubagentList lit le champ frontmatter "agents" (Copilot / Antigravity).
// Retourne (roster, present) ; "*" dans le roster signifie "tous".
func fmSubagentList(fm map[string]any) ([]string, bool) {
	items, present := fmItems(fm, "agents")
	if !present {
		return nil, false
	}
	var out []string
	for _, it := range items {
		if s, ok := it.(string); ok && s != "" {
			out = append(out, s)
		}
	}
	return out, true
}

// parseSubagentRules lit les règles permissions "subagent" au format OpenCode.
// (roster = autorisations explicites ; all = règle allow sur "*" ; deny = règle deny sur "*").
func parseSubagentRules(fm map[string]any) (roster []string, all, deny bool) {
	items, _ := fmItems(fm, "permissions")
	for _, it := range items {
		m, ok := it.(map[string]any)
		if !ok {
			continue
		}
		if fmString(m, "action") != "subagent" {
			continue
		}
		res := fmString(m, "resource")
		eff := fmString(m, "effect")
		switch {
		case eff == "allow" && res == "*":
			all = true
		case eff == "allow" && res != "":
			roster = append(roster, res)
		case eff == "deny" && res == "*":
			deny = true
		}
	}
	sort.Strings(roster)
	return roster, all, deny
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
	case []any:
		var parts []string
		for _, it := range v {
			if s, ok := it.(string); ok {
				parts = append(parts, s)
			}
		}
		return strings.Join(parts, " ")
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
