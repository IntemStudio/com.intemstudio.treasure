# Godot MCP

Cursor가 **켜 둔 Godot 에디터**에 붙는 개발 브리지.  
게임 시스템이 아니다. LSP(Godot Tools)나 외부 텍스트 에디터 설정과도 별개다.

이 프로젝트만 애드온을 허용한다. 게임 코드는 계속 Cursor가 파일을 고친다. MCP는 씬 트리, Play/Stop, Output/에러, 런타임 확인용.

패키지: [tomyud1/godot-mcp](https://github.com/tomyud1/godot-mcp) 0.5.0 (`npx godot-mcp-server` + `addons/godot_mcp`).

---

## 위치

| 역할 | 경로 |
|------|------|
| Cursor MCP 설정 | [`.cursor/mcp.json`](../../.cursor/mcp.json) |
| 에디터 플러그인 | [`addons/godot_mcp/`](../../addons/godot_mcp/) |
| 플러그인 enable | [`project.godot`](../../project.godot) `[editor_plugins]` |
| Play 중 런타임 | Autoload `MCPRuntime` → [`addons/godot_mcp/runtime/mcp_runtime.gd`](../../addons/godot_mcp/runtime/mcp_runtime.gd) |

연결: Cursor stdio → `godot-mcp-server` → WebSocket `127.0.0.1:6505` → Godot 플러그인.

---

## 레포에 이미 있는 것

클론하면 애드온과 `mcp.json`은 따라온다. AssetLib에서 다시 설치하지 않는다.

`.cursor/mcp.json`은 **Windows**용이다 (`cmd /c npx -y godot-mcp-server`). Mac/Linux면 `command`를 `npx`, `args`를 `["-y", "godot-mcp-server"]`로 바꾼다.

---

## 새 PC 순서

1. **Node.js LTS**를 설치한다. `npx`가 필요하다.
2. 레포를 클론하고 **Cursor로 이 폴더**를 연다.
3. **Cursor Settings → MCP**에서 `godot`을 켠다. 머신마다 승인한다. 첫 실행은 `npx`가 패키지를 받느라 시간이 걸린다.
4. **Godot에서 이 프로젝트를 연다.** 툴바에 MCP 상태가 떠야 한다. 에디터를 끄면 MCP는 죽는다.
5. Agent 모드에서 열린 씬 트리나 Output을 물어 연결을 확인한다. Ask 모드에서는 MCP 도구를 호출하지 않는다.

정상: Cursor MCP `godot`이 ready(도구 수십 개), Godot 툴바가 **MCP: Agent Active**, 서버 로그에 `Godot connected`.

---

## 쓸 때

- Godot이 이 프로젝트를 연 채로 둔다. 스크립트 외부 리로드가 켜져 있으면 Cursor 저장 후 Play로 바로 본다.
- 쓰기 도구는 **undo가 없다.** 씬을 만지기 전에 git 상태를 본다.
- `run_scene` / `get_errors` / `take_screenshot` / `send_input`은 게임이 돌아가야 한다. 스크린샷·입력은 `MCPRuntime`이 Play 세션에 붙어 있어야 한다.
- 익스포트 빌드에 `MCPRuntime`이 들어가면 localhost WebSocket을 시도한다. 릴리스 전에 플러그인을 끄거나 오토로드를 빼는 것을 검토한다.

---

## 같이 맞출 것 (MCP 아님)

Godot **Editor Settings**는 레포에 없다. 이 PC에서 Cursor를 외부 에디터로 쓰려면:

- Text Editor → External → Use External Editor
- Exec Path: `…/cursor/resources/app/bin/cursor.cmd`
- Exec Flags: `{project} --goto {file}:{line}:{col}`
- Auto Reload Scripts on External Change

Steam Godot 설정 파일은 `%APPDATA%\Godot\`가 아니라 설치 폴더 `editor_data/editor_settings-4.7.tres`다.
