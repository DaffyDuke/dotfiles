package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Structure source de VS Code (mcp.json)
type VSCodeConfig struct {
	Servers map[string]VSCodeServer `json:"servers"`
}

type VSCodeServer struct {
	Type    string            `json:"type,omitempty"`
	Command string            `json:"command,omitempty"`
	Args    []string          `json:"args,omitempty"`
	Env     map[string]string `json:"env,omitempty"`
	URL     string            `json:"url,omitempty"`
}

// Structure Standard MCP (Antigravity & Copilot CLI)
type StandardConfig struct {
	MCPServers map[string]StandardServer `json:"mcpServers"`
}

type StandardServer struct {
	Command string            `json:"command,omitempty"`
	Args    []string          `json:"args,omitempty"`
	Env     map[string]string `json:"env,omitempty"`
	URL     string            `json:"url,omitempty"`
}

// Structure OpenCode / Mammouth (opencode.jsonc / mammouth.jsonc)
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

	fmt.Println("=== Synchronisation des MCP et Skills IA (Go) ===")

	vscodeMcpPath := filepath.Join(homeDir, ".config/Code/User/mcp.json")
	if _, err := os.Stat(vscodeMcpPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Fichier source VS Code introuvable : %s\n", vscodeMcpPath)
		os.Exit(1)
	}

	rawBytes, err := os.ReadFile(vscodeMcpPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lecture %s : %v\n", vscodeMcpPath, err)
		os.Exit(1)
	}

	var vsConfig VSCodeConfig
	if err := json.Unmarshal(rawBytes, &vsConfig); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur parsing JSON %s : %v\n", vscodeMcpPath, err)
		os.Exit(1)
	}

	servers := vsConfig.Servers
	if servers == nil {
		servers = make(map[string]VSCodeServer)
	}
	fmt.Printf("Serveurs détectés dans VS Code : %d\n", len(servers))

	// 1. Convertir au format Standard (Antigravity & Copilot CLI)
	stdServers := make(map[string]StandardServer)
	for name, srv := range servers {
		if srv.Type == "http" || srv.URL != "" {
			stdServers[name] = StandardServer{
				URL: srv.URL,
			}
		} else {
			cmd := srv.Command
			if cmd == "" {
				cmd = "npx"
			}
			s := StandardServer{
				Command: cmd,
				Args:    srv.Args,
			}
			if len(srv.Env) > 0 {
				s.Env = srv.Env
			}
			stdServers[name] = s
		}
	}

	stdConfig := StandardConfig{MCPServers: stdServers}
	stdJson, err := json.MarshalIndent(stdConfig, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur sérialisation standard : %v\n", err)
		os.Exit(1)
	}
	stdJson = append(stdJson, '\n')

	geminiPath := filepath.Join(homeDir, ".gemini/config/mcp_config.json")
	writeConfigFile(geminiPath, stdJson)
	fmt.Printf("[✓] Antigravity MCP synchronisé -> %s\n", geminiPath)

	copilotPath := filepath.Join(homeDir, ".copilot/mcp-config.json")
	writeConfigFile(copilotPath, stdJson)
	fmt.Printf("[✓] Copilot CLI MCP synchronisé -> %s\n", copilotPath)

	// 2. Convertir au format OpenCode & Mammouth
	opencodeServers := make(map[string]OpenCodeServer)
	for name, srv := range servers {
		if srv.Type == "http" || srv.URL != "" {
			opencodeServers[name] = OpenCodeServer{
				Type: "remote",
				URL:  srv.URL,
			}
		} else {
			cmd := srv.Command
			if cmd == "" {
				cmd = "npx"
			}
			fullCmd := append([]string{cmd}, srv.Args...)
			osrv := OpenCodeServer{
				Type:    "local",
				Command: fullCmd,
			}
			if len(srv.Env) > 0 {
				envMap := make(map[string]string)
				for k, v := range srv.Env {
					if strings.HasPrefix(v, "${") && strings.HasSuffix(v, "}") {
						varName := v[2 : len(v)-1]
						envMap[k] = fmt.Sprintf("{env:%s}", varName)
					} else {
						envMap[k] = v
					}
				}
				osrv.Environment = envMap
			}
			opencodeServers[name] = osrv
		}
	}

	mammouthPath := filepath.Join(homeDir, ".config/mammouth/mammouth.jsonc")
	updateToolJsonConfig(mammouthPath, opencodeServers)
	fmt.Printf("[✓] Mammouth CLI MCP synchronisé -> %s\n", mammouthPath)

	opencodePath := filepath.Join(homeDir, ".config/opencode/opencode.jsonc")
	updateToolJsonConfig(opencodePath, opencodeServers)
	fmt.Printf("[✓] OpenCode MCP synchronisé -> %s\n", opencodePath)

	// 3. Liaison symbolique des Skills
	centralSkills := filepath.Join(homeDir, ".local/share/ai-skills")
	if err := os.MkdirAll(centralSkills, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création dossier central skills : %v\n", err)
	}

	skillTargets := []string{
		filepath.Join(homeDir, ".config/opencode/skills"),
		filepath.Join(homeDir, ".gemini/config/skills"),
		filepath.Join(homeDir, ".copilot/skills"),
		filepath.Join(homeDir, ".config/mammouth/skills"),
	}

	for _, target := range skillTargets {
		ensureSymlink(centralSkills, target)
	}
	fmt.Printf("[✓] Skills unifiés et interconnectés -> %s\n", centralSkills)
	fmt.Println("Synchronisation terminée avec succès !")
}

func writeConfigFile(targetPath string, content []byte) {
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création répertoire %s : %v\n", filepath.Dir(targetPath), err)
		return
	}
	if err := os.WriteFile(targetPath, content, 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur écriture %s : %v\n", targetPath, err)
	}
}

func updateToolJsonConfig(filePath string, mcpMap map[string]OpenCodeServer) {
	var root map[string]interface{}

	if data, err := os.ReadFile(filePath); err == nil {
		_ = json.Unmarshal(data, &root)
	}
	if root == nil {
		root = make(map[string]interface{})
		root["$schema"] = "https://opencode.ai/config.json"
	}

	root["mcp"] = mcpMap
	outBytes, err := json.MarshalIndent(root, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur sérialisation %s : %v\n", filePath, err)
		return
	}
	outBytes = append(outBytes, '\n')
	writeConfigFile(filePath, outBytes)
}

func ensureSymlink(centralPath, targetPath string) {
	_ = os.MkdirAll(filepath.Dir(targetPath), 0755)

	fi, err := os.Lstat(targetPath)
	if err == nil {
		if fi.Mode()&os.ModeSymlink != 0 {
			linkDest, err := os.Readlink(targetPath)
			if err == nil && linkDest == centralPath {
				return // Déjà valide
			}
		}
		_ = os.RemoveAll(targetPath)
	}

	if err := os.Symlink(centralPath, targetPath); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création lien symbolique %s -> %s : %v\n", targetPath, centralPath, err)
	}
}
