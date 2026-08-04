# 内容数据 Schema · 数据驱动对话树（Phase 2）

> Owner：design-strategist（文策渊）
> 用途：让全部场景文案由数据驱动，表现层（Godot）只消费本结构，不写死文案。
> 关联：`design/gdd/系统设计_系统拆解.md`（S1 内容数据层）｜`design/gdd/垂直切片GDD_s01_s03_s04.md`

---

## 1. 设计原则

- **单一事实源**：一个场景 = 一条数据记录；S2–S8 全部消费它。
- **可评审**：Lean 阶段用静态 JSON/YAML，后果为查表映射，无脚本逻辑。
- **可扩展**：s01–s34 后续技能沿用同一结构，仅填数据。
- **Godot 友好**：JSON 可被 Godot 原生 `JSON.parse_string()` 解析；建议每技能一个 `.json`，或统一 `scenarios.json` 数组。最终加载方式由工程侧（程基岩）在 Phase 3 定。

---

## 2. Schema 定义（字段表）

### 顶层 Scenario
| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | 全局唯一，如 `s01_scene_01` |
| `skill` | string | ✅ | 技能 id，如 `s01-shake-the-hive` |
| `title` | string | ✅ | 场景标题（地图/复盘用） |
| `context` | string | ✅ | 情境背景 |
| `npc` | object | ✅ | `{ name, role, mood, line? }` |
| `impulse` | string | ✅ | 玩家本能念头（气泡） |
| `schemaVersion` | string | — | 默认 `"1"`；标识本记录所用 Schema 版本，为未来 `schema_v2` 演进预留（G4）。MVP 数据可省略，加载期缺省视为 1 |
| `triggers` | object | ✅ | 见下 |
| `choices` | array | ✅ | 2–4 项，见下 |
| `review` | object | ✅ | 见下 |
| `forceBoundary` | bool | — | 默认 false；true 时遇安全/合规强制走 boundary |

### npc
| 字段 | 类型 | 说明 |
|---|---|---|
| `name` | string | 对方名字 |
| `role` | string | 对方身份（下属 / 同事 / 客户…） |
| `mood` | string | 情绪关键词（供表现层微表情剪影） |
| `line` | string | **可选**；对方最后一句台词或动作，供 S2 场景卡渲染（满足切片 GDD §6「对方台词」）。缺省则场景卡仅用 `context` + `impulse` |

### triggers
| 字段 | 类型 | 说明 |
|---|---|---|
| `candidates` | string[] | 2–4 个候选标签 |
| `correct` | string | 正确标签（须 ∈ candidates） |
| `miss` | object | **可选**；识别错误时播放的 consequence，结构与 `consequence` 同构（`npcReaction` / `relationshipSignal` / `judgement`）。G2 方案A 引擎规则：识别错误 → **永远**播放 `miss`（清晰、可感知的错位后果），不再依赖选项错位自然反噬；缺省则回退原逻辑（S3 让选项错位，后果由所选选项 `consequence` 决定） |

### choices[]（单选项）
| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 选项 id，如 `c1` |
| `type` | enum | `skilled` / `trap` / `boundary` |
| `text` | string | 玩家实际会说的话（真实、诱惑或合理） |
| `consequence` | object | 见下 |

### consequence
| 字段 | 类型 | 说明 |
|---|---|---|
| `npcReaction` | string | 对方反应台词 |
| `relationshipSignal` | int | `-1 / 0 / +1`，**仅展示不持久化**（S9 扩展层才累积） |
| `judgement` | string | 一句后果判词 |

### review
| 字段 | 类型 | 说明 |
|---|---|---|
| `mechanism` | string | 机制原理（WHY，对应 I 段） |
| `case` | string | 真实历史案例（对应 A1 段） |
| `migration` | string | 迁移线索（下次怎么做） |

> **P2 已移除**：本 Schema **无** `ethicsGate` / `boundaryWarn` 字段；复盘不含额外伦理批注。如扩展层需加，单独版本化，不影响 MVP。

---

## 3. 真实示例 — s01_scene_01（JSON）

取自 s01「打翻蜂巢」A2 触发（起草列举对方过失的评语）+ E 步骤（改写目标指向未来 / 净收益核算 / 僵局特判）。

```json
{
  "schemaVersion": "1",
  "id": "s01_scene_01",
  "skill": "s01-shake-the-hive",
  "title": "那封绩效评语",
  "context": "你正在给下属小陈写季度绩效评语，心里列了三条他这季度犯过的错，想「把话说清楚」。",
  "npc": { "name": "小陈", "role": "下属", "mood": "defensive-anticipating", "line": "（小陈把一叠需求变更记录丢在桌上：『反正我按你说的做了，对不对你自己看。』）" },
  "impulse": "我得让他知道自己错在哪，不然他不会改。",
  "triggers": {
    "candidates": [
      "我正想批评 / 对方在防御",
      "对方需要被看见",
      "纯事务沟通",
      "对方在撒谎"
    ],
    "correct": "我正想批评 / 对方在防御",
    "miss": {
      "npcReaction": "（他没等你解释，先开口争辩起上季度另一件事）",
      "relationshipSignal": -1,
      "judgement": "你没先看清「他在防御」就进了抉择，局面已被拖进对抗；先诊断再动手。"
    }
  },
  "choices": [
    {
      "id": "c1",
      "type": "trap",
      "text": "把他这季度三次延误和需求变更漏报都列出来，让他看清楚问题。",
      "consequence": {
        "npcReaction": "（沉默了一会儿）……我明白了。",
        "relationshipSignal": -1,
        "judgement": "他进入防御、开始准备自辩叙事；未来每次合作都要付更高价。对方自责概率约 1%。"
      }
    },
    {
      "id": "c2",
      "type": "skilled",
      "text": "把「让他认错」换成「下周三前把接口文档补齐」的具体目标，不评价过去。",
      "consequence": {
        "npcReaction": "好，我周三前补上。",
        "relationshipSignal": 1,
        "judgement": "绕开自辩，直接指向未来行为；协作未转为对抗，关系账户未透支。"
      }
    },
    {
      "id": "c3",
      "type": "boundary",
      "text": "涉及合规漏报，必须正式记录并叫停，不软化。",
      "consequence": {
        "npcReaction": "（被要求书面说明情况）",
        "relationshipSignal": 0,
        "judgement": "安全 / 合规红线不在本技能范围，必须叫停而非绕开——「不批评」让位于「叫停」。"
      }
    }
  ],
  "review": {
    "mechanism": "批评在结构上手段与目的相悖：自尊被归因→对方进入防御→士气下降，而「被指责的事」不会因此改善；对方自责概率约 1%，且错误越严重越低。",
    "case": "罗斯福公开批评塔夫脱→共和党分裂惨败；314 名员工老板停批评改赞赏→利润增加、闲暇增多。",
    "migration": "下次起草「说清楚」的消息前，先逐句问：这句话会不会让他想自辩？若会，改写为不含「评价过去」的未来行为目标。"
  }
}
```

---

## 4. YAML 变体（同场景，供偏好 YAML 的管线）

```yaml
- schemaVersion: "1"
  id: s01_scene_01
  skill: s01-shake-the-hive
  title: 那封绩效评语
  context: 你正在给下属小陈写季度绩效评语，心里列了三条他这季度犯过的错，想「把话说清楚」。
  npc:
    name: 小陈
    role: 下属
    mood: defensive-anticipating
    line: （小陈把一叠需求变更记录丢在桌上：『反正我按你说的做了，对不对你自己看。』）
  impulse: 我得让他知道自己错在哪，不然他不会改。
  triggers:
    candidates:
      - 我正想批评 / 对方在防御
      - 对方需要被看见
      - 纯事务沟通
      - 对方在撒谎
    correct: 我正想批评 / 对方在防御
    miss:
      npcReaction: （他没等你解释，先开口争辩起上季度另一件事）
      relationshipSignal: -1
      judgement: 你没先看清「他在防御」就进了抉择，局面已被拖进对抗；先诊断再动手。
  choices:
    - id: c1
      type: trap
      text: 把他这季度三次延误和需求变更漏报都列出来，让他看清楚问题。
      consequence:
        npcReaction: （沉默了一会儿）……我明白了。
        relationshipSignal: -1
        judgement: 他进入防御、开始准备自辩叙事；未来每次合作都要付更高价。对方自责概率约 1%。
    - id: c2
      type: skilled
      text: 把「让他认错」换成「下周三前把接口文档补齐」的具体目标，不评价过去。
      consequence:
        npcReaction: 好，我周三前补上。
        relationshipSignal: 1
        judgement: 绕开自辩，直接指向未来行为；协作未转为对抗，关系账户未透支。
    - id: c3
      type: boundary
      text: 涉及合规漏报，必须正式记录并叫停，不软化。
      consequence:
        npcReaction: （被要求书面说明情况）
        relationshipSignal: 0
        judgement: 安全 / 合规红线不在本技能范围，必须叫停而非绕开——「不批评」让位于「叫停」。
  review:
    mechanism: 批评在结构上手段与目的相悖：自尊被归因→对方进入防御→士气下降，而「被指责的事」不会因此改善；对方自责概率约 1%。
    case: 罗斯福公开批评塔夫脱→共和党分裂惨败；314 名员工老板停批评改赞赏→利润增加、闲暇增多。
    migration: 下次起草「说清楚」的消息前，先逐句问：这句话会不会让他想自辩？
```

---

## 5. 工程侧约束（供主理人转交程基岩）

1. **结构即契约**：S2–S8 仅读本 Schema 字段；新增场景只增数据，不改代码。
2. **加载建议**：每技能一个 `.json`（如 `s01.json`）或统一数组；Godot 用 `FileAccess` + `JSON.parse_string()`；中文需确认导出/编码为 UTF-8。
3. **关系信号不持久化**：`relationshipSignal` 仅本局演出；S9 账户延后，勿在 MVP 做累积存储。
4. **校验**：加载期校验 `triggers.correct ∈ candidates`、`choices` 含 ≥1 `skilled`、字段齐全；若存在 `triggers.miss` 须与 `consequence` 同构（含 `npcReaction`/`relationshipSignal`/`judgement`）；缺失 `review.case` 允许降级而非崩溃。
5. **无逻辑脚本**：MVP 后果为查表，不在数据里写条件分支/随机；保持 Lean 与可评审。
6. **P2 字段缺席**：Schema 不含 `ethicsGate`；若后续扩展层要加，单独版本（如 `schema_v2`）以免污染 MVP 数据。
7. **版本演进（G4）**：记录可带 `schemaVersion`（MVP 缺省 `"1"`）；未来 `schema_v2` 以新增可选字段 / `miss` reintroduce s05 质量门等方式演进，向后兼容，不破坏 v1 数据加载。
