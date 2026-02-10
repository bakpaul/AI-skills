# Using the CMake Skill with Local Claude Agents

This guide explains how to use the CMake skill with different local Claude configurations.

## Table of Contents

1. [With Claude Desktop (MCP)](#with-claude-desktop-mcp)
2. [With Claude API + Context Window](#with-claude-api--context-window)
3. [With Claude Code (CLI)](#with-claude-code-cli)
4. [With a Custom Agent](#with-a-custom-agent)
5. [With OpenCode](#with-opencode)

---

## With Claude Desktop (MCP)

Claude Desktop supports skills through custom prompts and MCP servers.

### Method 1: System Prompt (Simple)

1. **Extract the skill:**
   ```bash
   tar -xzf cmake-skill-complete.tar.gz
   cd cmake-skill
   ```

2. **Copy SKILL.md content** to clipboard:
   ```bash
   cat SKILL.md | pbcopy  # macOS
   # or
   cat SKILL.md | xclip -selection clipboard  # Linux
   ```

3. **In Claude Desktop:**
   - Open a new conversation
   - Start with: "You are a CMake expert. Here are your instructions: [paste SKILL.md]"
   - Then ask your CMake questions

**Advantage:** Simple and immediate  
**Disadvantage:** Need to paste the skill in each new conversation

### Method 2: Custom Instructions (Persistent)

If Claude Desktop supports custom instructions (depending on version):

1. **Go to Settings > Custom Instructions**

2. **Add SKILL.md content** to system instructions

3. **Enable for all CMake conversations**

**Advantage:** Persistent, no need to repaste  
**Disadvantage:** May not be available in all versions

### Method 3: MCP Server (Advanced)

Create an MCP server that exposes the skill:

1. **Create an MCP server:**

```typescript
// cmake-skill-server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import fs from "fs";
import path from "path";

const SKILL_PATH = "/path/to/cmake-skill/SKILL.md";

const server = new Server(
  {
    name: "cmake-skill-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      resources: {},
    },
  }
);

server.setRequestHandler("resources/list", async () => {
  return {
    resources: [
      {
        uri: "cmake-skill://skill",
        name: "CMake Expert Skill",
        description: "Expert guidance for CMake 4",
        mimeType: "text/markdown",
      },
    ],
  };
});

server.setRequestHandler("resources/read", async (request) => {
  if (request.params.uri === "cmake-skill://skill") {
    const content = fs.readFileSync(SKILL_PATH, "utf-8");
    return {
      contents: [
        {
          uri: request.params.uri,
          mimeType: "text/markdown",
          text: content,
        },
      ],
    };
  }
  throw new Error("Resource not found");
});

const transport = new StdioServerTransport();
server.connect(transport);
```

2. **Configure in Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "cmake-skill": {
      "command": "node",
      "args": ["/path/to/cmake-skill-server.js"]
    }
  }
}
```

3. **Use in Claude:**
   - The skill will be available as a resource
   - Claude can access it automatically when you ask CMake questions

**Advantage:** Native integration, automatic skill updates  
**Disadvantage:** More complex to configure

---

## With Claude API + Context Window

If you're using the Claude API directly in your code:

### Python Example

```python
import anthropic
import os

# Load the skill
with open("cmake-skill/SKILL.md", "r") as f:
    cmake_skill = f.read()

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

# Create a conversation with the skill
message = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=4096,
    system=cmake_skill,  # The skill as system prompt
    messages=[
        {
            "role": "user",
            "content": "I'd like to create a shared library with CMake. Can you give me a complete example?"
        }
    ]
)

print(message.content[0].text)
```

### Node.js Example

```javascript
import Anthropic from "@anthropic-ai/sdk";
import fs from "fs";

// Load the skill
const cmakeSkill = fs.readFileSync("cmake-skill/SKILL.md", "utf-8");

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const message = await client.messages.create({
  model: "claude-sonnet-4-20250514",
  max_tokens: 4096,
  system: cmakeSkill, // The skill as system prompt
  messages: [
    {
      role: "user",
      content: "How do I debug find_package issues?",
    },
  ],
});

console.log(message.content[0].text);
```

### Interactive Script

```python
#!/usr/bin/env python3
import anthropic
import os

# Load the skill
with open("cmake-skill/SKILL.md", "r") as f:
    CMAKE_SKILL = f.read()

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

def ask_cmake(question: str) -> str:
    """Ask a CMake question using the skill"""
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        system=CMAKE_SKILL,
        messages=[{"role": "user", "content": question}]
    )
    return message.content[0].text

# Interactive interface
if __name__ == "__main__":
    print("CMake Expert Assistant (powered by skill)")
    print("Type 'exit' to quit\n")
    
    while True:
        question = input("CMake Question: ")
        if question.lower() == "exit":
            break
        
        answer = ask_cmake(question)
        print(f"\nAnswer:\n{answer}\n")
```

**Advantage:** Full control, scriptable  
**Disadvantage:** Requires API key and coding

---

## With Claude Code (CLI)

Claude Code is a CLI tool for developers that supports "skills".

### Configuration

1. **Install Claude Code:**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Configure the skill:**
   ```bash
   # Create skills directory
   mkdir -p ~/.claude-code/skills
   
   # Copy the skill
   cp -r cmake-skill ~/.claude-code/skills/
   ```

3. **Use the skill:**
   ```bash
   claude-code --skill cmake "How do I create a distributable library?"
   ```

**Note:** Check Claude Code documentation for exact syntax, as it may vary by version.

---

## With a Custom Agent

If you're building your own local agent:

### Recommended Structure

```python
class CMakeAgent:
    def __init__(self, skill_path: str):
        # Load the skill
        with open(skill_path, "r") as f:
            self.skill = f.read()
        
        # Load examples
        self.examples = self._load_examples()
        
        # Initialize Claude
        self.client = anthropic.Anthropic(
            api_key=os.environ.get("ANTHROPIC_API_KEY")
        )
    
    def _load_examples(self) -> dict:
        """Load examples from examples/ directory"""
        examples = {}
        examples_dir = "cmake-skill/examples"
        
        for example in os.listdir(examples_dir):
            example_path = os.path.join(examples_dir, example)
            if os.path.isdir(example_path):
                examples[example] = self._load_example_files(example_path)
        
        return examples
    
    def ask(self, question: str, context: dict = None) -> str:
        """
        Ask a CMake question with optional context
        
        Args:
            question: The CMake question
            context: Additional context (project files, errors, etc.)
        """
        # Build prompt with context
        prompt = question
        
        if context:
            if "error" in context:
                prompt += f"\n\nError message:\n{context['error']}"
            
            if "cmake_file" in context:
                prompt += f"\n\nCurrent CMakeLists.txt:\n{context['cmake_file']}"
        
        # Call Claude with the skill
        message = self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4096,
            system=self.skill,
            messages=[{"role": "user", "content": prompt}]
        )
        
        return message.content[0].text
    
    def get_example(self, example_name: str) -> dict:
        """Get a complete example"""
        return self.examples.get(example_name)

# Usage
agent = CMakeAgent("cmake-skill/SKILL.md")

# Simple question
answer = agent.ask("How do I create a shared library?")
print(answer)

# Question with context
context = {
    "error": "CMake Error: find_package could not find MyLib",
    "cmake_file": open("CMakeLists.txt").read()
}
answer = agent.ask("Why isn't my find_package working?", context)
print(answer)

# Get an example
library_example = agent.get_example("library")
print(library_example["CMakeLists.txt"])
```

---

## With OpenCode

OpenCode is a very popular open-source coding agent (95k+ GitHub stars, 2.5M+ monthly users) that natively supports custom agents.

### Installation

```bash
# Via npm
npm i -g opencode-ai@latest

# Via Homebrew (macOS/Linux - recommended)
brew install anomalyco/tap/opencode

# Via install script
curl -fsSL https://opencode.ai/install | bash
```

### Method 1: Custom Agent (Recommended)

OpenCode allows creating agents with dedicated system prompts.

**Create the CMake agent manually:**

File `~/.config/opencode/agents/cmake-expert.md`:

````markdown
---
name: cmake-expert  
description: CMake expert for build systems
mode: primary
model: anthropic/claude-sonnet-4-20250514
temperature: 0.2
tools:
  read: true
  grep: true
  edit: true
  bash: true
permissions:
  bash: ask
  edit: ask
---

[Paste SKILL.md content here]
````

**Use the agent:**

```bash
# Launch OpenCode with the agent
opencode --agent cmake-expert

# Or non-interactive mode
opencode --agent cmake-expert -p "How do I create a shared library?"
```

### Method 2: Project Configuration

For a specific CMake project, create `.opencode/opencode.json`:

```json
{
  "default_agent": "cmake-expert",
  "agents": {
    "cmake-expert": {
      "mode": "primary",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "file://.opencode/cmake-skill.md"
    }
  }
}
```

Copy the skill:
```bash
mkdir -p .opencode
cp path/to/cmake-skill/SKILL.md .opencode/cmake-skill.md
```

The CMake agent will be active by default in this project!

### Method 3: Custom Commands

Create `~/.config/opencode/commands/cmake-help.md`:

````markdown
---
id: cmake-help
description: CMake expert help
---

You are a CMake expert following modern best practices.

Help with: $TOPIC
````

Usage: `/cmake-help find_package`

### Method 4: Via Server API

```bash
# Start server
opencode serve --port 3000
```

```python
import requests

response = requests.post("http://localhost:3000/api/sessions", json={
    "agent": "cmake-expert",
    "messages": [{
        "role": "user",
        "content": "How do I use FetchContent?"
    }]
})
```

### CMake Auto-detection

Configuration to activate agent automatically:

```json
{
  "hooks": {
    "session_start": {
      "trigger": "file_exists:CMakeLists.txt",
      "action": "set_agent:cmake-expert"
    }
  }
}
```

### OpenCode Advantages

- ✅ Dedicated agent always available
- ✅ Native terminal integration
- ✅ Persistent configuration
- ✅ Multi-agents with easy switch (Tab)
- ✅ Project-specific configs
- ✅ MCP support for additional tools

### Resources

- Official site: https://opencode.ai/
- Agent documentation: https://opencode.ai/docs/agents/
- GitHub: https://github.com/anomalyco/opencode

---

## Using with Computer Use

If you're using Claude with computer use (like in this conversation):

```python
# The skill is already mounted in /mnt/skills/
# You can access it directly

# In your code:
import os

SKILL_PATH = "/mnt/skills/user/cmake/SKILL.md"

def use_cmake_skill():
    """Use the mounted CMake skill"""
    with open(SKILL_PATH, "r") as f:
        skill_content = f.read()
    
    # The skill is now in context
    return skill_content
```

---

## Best Practices

### 1. Context Window Management

The skill is ~20KB. To optimize:

```python
# Extract only relevant sections
def get_relevant_section(skill_content: str, topic: str) -> str:
    """Extract relevant section from skill"""
    sections = {
        "find_package": "### Understanding find_package()",
        "fetchcontent": "### Automatic Dependency Fetching with FetchContent",
        "functions": "### Functions, Macros, and Scope Management",
        # etc.
    }
    
    start_marker = sections.get(topic)
    if not start_marker:
        return skill_content
    
    # Extract the section
    start = skill_content.find(start_marker)
    # Find next section of same level
    next_section = skill_content.find("\n### ", start + 1)
    
    if next_section == -1:
        return skill_content[start:]
    return skill_content[start:next_section]
```

### 2. Caching

To avoid reloading the skill each time:

```python
class CMakeSkillCache:
    _instance = None
    _skill = None
    
    @classmethod
    def get_skill(cls, path: str) -> str:
        if cls._skill is None:
            with open(path, "r") as f:
                cls._skill = f.read()
        return cls._skill

# Usage
skill = CMakeSkillCache.get_skill("cmake-skill/SKILL.md")
```

### 3. Using with File Context

```python
def analyze_cmake_project(project_path: str, question: str):
    """Analyze a CMake project with the skill"""
    
    # Load the skill
    skill = load_skill("cmake-skill/SKILL.md")
    
    # Read project files
    cmake_files = []
    for root, dirs, files in os.walk(project_path):
        for file in files:
            if file == "CMakeLists.txt":
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    cmake_files.append({
                        "path": filepath,
                        "content": f.read()
                    })
    
    # Build context
    context = "Project CMakeLists.txt files:\n\n"
    for cmake_file in cmake_files:
        context += f"=== {cmake_file['path']} ===\n"
        context += cmake_file['content']
        context += "\n\n"
    
    # Ask question with context
    prompt = f"{context}\n\nQuestion: {question}"
    
    # Call Claude
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        system=skill,
        messages=[{"role": "user", "content": prompt}]
    )
    
    return message.content[0].text
```

---

## Complete Usage Examples

### Interactive CLI Script

```bash
#!/bin/bash
# cmake-assistant.sh

SKILL_PATH="$HOME/.local/share/cmake-skill/SKILL.md"

# Load skill into variable
SKILL=$(cat "$SKILL_PATH")

# Function to ask a question
ask_cmake() {
    local question="$1"
    
    # Use Claude API (requires anthropic CLI or curl)
    curl https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-sonnet-4-20250514\",
            \"max_tokens\": 4096,
            \"system\": $(echo "$SKILL" | jq -Rs .),
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $(echo "$question" | jq -Rs .)
            }]
        }" | jq -r '.content[0].text'
}

# Interface
echo "CMake Expert Assistant"
echo "Type your question or 'exit' to quit"
echo ""

while true; do
    read -p "cmake> " question
    
    if [ "$question" = "exit" ]; then
        break
    fi
    
    echo ""
    ask_cmake "$question"
    echo ""
done
```

---

## Troubleshooting

### The skill is too large for context window

**Solution:** Split the skill into sections and load only what's relevant

```python
SKILL_SECTIONS = {
    "core": ["What is a Target?", "Understanding find_package()"],
    "advanced": ["FetchContent", "Functions, Macros"],
    "workflow": ["Creating Shared Libraries", "Debugging find_package"]
}

def load_skill_section(section_name: str) -> str:
    """Load only one section of the skill"""
    # Implementation...
```

### Claude doesn't follow the skill well

**Solution:** Add a reminder in the user prompt

```python
user_prompt = f"""
Following the CMake expert skill guidelines, please help me with:

{user_question}

Remember to:
- Check documentation if uncertain
- Provide complete examples
- Use modern target-based approach
"""
```

### Examples are not accessible

**Solution:** Expose examples as separate files or include them in context

```python
# Include a relevant example
def include_example(example_name: str, user_question: str) -> str:
    example_path = f"cmake-skill/examples/{example_name}"
    
    files = {}
    for root, dirs, filenames in os.walk(example_path):
        for filename in filenames:
            filepath = os.path.join(root, filename)
            with open(filepath) as f:
                files[filename] = f.read()
    
    context = f"Relevant example ({example_name}):\n\n"
    for filename, content in files.items():
        context += f"=== {filename} ===\n{content}\n\n"
    
    return context + user_question
```

---

## Conclusion

The CMake skill can be used in several ways:

1. **Simple:** Copy-paste into Claude Desktop
2. **Integrated:** Via MCP server in Claude Desktop  
3. **Programmatic:** Via API with system prompt
4. **Custom:** In your own local agent
5. **OpenCode:** Dedicated agent in terminal ⭐

Choose the method that best fits your workflow!
