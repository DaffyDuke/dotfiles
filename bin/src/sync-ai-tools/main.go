package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
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

// 1. Format Canonique Central & VS Code (~/.local/share/ai-skills/mcp.json & ~/.config/Code/User/mcp.json)
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

func main() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Impossible de déterminer le répertoire HOME : %v\n", err)
		os.Exit(1)
	}

	fmt.Println("=== Synchronisation des MCP & Skills IA (Hub Central ~/.local/share/ai-skills) ===")

	centralSkillsDir := filepath.Join(homeDir, ".local/share/ai-skills")
	centralMcpPath := filepath.Join(centralSkillsDir, "mcp.json")

	_ = os.MkdirAll(centralSkillsDir, 0755)

	// Carte globale de tous les serveurs unifiés
	mergedServers := make(map[string]UnifiedServer)

	// Chemins des 5 clients
	vscodePath := filepath.Join(homeDir, ".config/Code/User/mcp.json")
	geminiPath := filepath.Join(homeDir, ".gemini/config/mcp_config.json")
	copilotPath := filepath.Join(homeDir, ".copilot/mcp-config.json")
	mammouthPath := filepath.Join(homeDir, ".config/mammouth/mammouth.jsonc")
	opencodePath := filepath.Join(homeDir, ".config/opencode/opencode.jsonc")

	// --- Étape A : COLLECTE & FUSION (Merge) ---
	// 1. Lire d'abord la source centrale (prioritaire)
	readCanonicalServers(centralMcpPath, "Central ai-skills/mcp.json", mergedServers)

	// 2. Lire les configurations de tous les clients existants pour capter tout ajout local
	readCanonicalServers(vscodePath, "VS Code", mergedServers)
	readStandardServers(geminiPath, "Antigravity", mergedServers)
	readStandardServers(copilotPath, "Copilot CLI", mergedServers)
	readOpenCodeServers(mammouthPath, "Mammouth", mergedServers)
	readOpenCodeServers(opencodePath, "OpenCode", mergedServers)

	fmt.Printf("\nTotal de serveurs MCP uniques identifiés après fusion : %d\n\n", len(mergedServers))

	// --- Étape B : ÉCRITURE DANS LE HUB CENTRAL ---
	writeCanonicalConfig(centralMcpPath, mergedServers)
	fmt.Printf("[✓] Hub central mis à jour -> %s\n", centralMcpPath)

	// --- Étape C : DISTRIBUTION AUX 5 OUTILS ---
	// 1. VS Code
	writeCanonicalConfig(vscodePath, mergedServers)
	fmt.Printf("[✓] VS Code mis à jour -> %s\n", vscodePath)

	// 2. Antigravity
	writeStandardConfig(geminiPath, mergedServers)
	fmt.Printf("[✓] Antigravity mis à jour -> %s\n", geminiPath)

	// 3. Copilot CLI
	writeStandardConfig(copilotPath, mergedServers)
	fmt.Printf("[✓] Copilot CLI mis à jour -> %s\n", copilotPath)

	// 4. Mammouth CLI
	writeOpenCodeConfig(mammouthPath, mergedServers)
	fmt.Printf("[✓] Mammouth CLI mis à jour -> %s\n", mammouthPath)

	// 5. OpenCode
	writeOpenCodeConfig(opencodePath, mergedServers)
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
			if _, hasKey := existing.Env[k]; !hasKey {
				existing.Env[k] = v
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
