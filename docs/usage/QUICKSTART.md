# Quick Start Guide (Pragmatic Approach)

**Get from idea to working code with Claude orchestrating agents.**

---

## This Is a Template Repository

Everything is already set up. No installation needed - just use it!

### What's Included:

```bash
.claude/
├── agents/          # 27 agent definitions (markdown)
├── commands/        # 3 slash commands (markdown prompts)
├── settings.json    # Agent configuration
└── CLAUDE.md        # System overview

docs/               # Documentation structure (agents will populate)
src/                # Source code (agents will create)
tests/              # Tests (agents will create)
```

**Time:** 0 minutes - it's ready to use!

---

## 15-Minute Planning

### Generate PRD

```bash
/prd
```

**Answer these questions:**

1. **Tech Stack** (asked first)
   ```
   "What integrations do you need?"
   → Your answer determines Python vs TypeScript recommendation
   ```

2. **Problem & Solution**
   ```
   "What problem are you solving, and for whom?"
   "What is your proposed solution?"
   ```

3. **Users & Requirements**
   ```
   "Who are the users?"
   "What are the must-have features?"
   ```

4. **Success Criteria**
   ```
   "How do you know it works?"
   "What metrics indicate success?"
   ```

5. **Constraints**
   ```
   "Timeline requirements?"
   "Budget limits?"
   "Security requirements?"
   ```

**Output:** `docs/planning/PROJECT_PRD.yaml`

### Generate Tasks & Sprints

```bash
/planning
```

**What Claude does:**
1. Launches task-graph-analyzer agent
2. Launches sprint-planner agent
3. Creates task and sprint files

**Output:**
- `docs/planning/tasks/TASK-001.yaml` through `TASK-XXX.yaml`
- `docs/sprints/SPRINT-001.yaml` through `SPRINT-XXX.yaml`
- Dependency graph

**Review:**
- Check task count (10-30 is typical)
- Verify dependencies make sense
- Confirm acceptance criteria are clear
- Check task types (fullstack/backend/frontend/python-generic)
- Check sprint count (2-5 is typical)
- Verify sprint goals align with priorities

---

## Claude-Orchestrated Execution

### Execute Sprint

```bash
/sprint SPRINT-001
```

**What Claude orchestrates:**
1. Claude reads sprint plan
2. For each task:
   - Claude determines workflow type
   - Claude launches specialized agents using Task tool (database → api → frontend → tests → security → docs)
   - **T1 agents (Haiku) for iterations 1-2** (cost-optimized)
   - Claude launches requirements-validator agent
   - If fails: Claude notes gaps, increments iteration
   - If fails iteration 3+: **Claude switches to T2 agents (Sonnet)** (enhanced quality)
   - If passes: Claude moves to next task
3. Sprint complete when Claude has orchestrated all tasks

**You monitor Claude's orchestration progress.**

### Monitor Progress

**Watch Claude's responses:**
- Claude reports after each agent completes
- Claude shows iteration numbers
- Claude indicates T1/T2 usage
- Claude reports validation results

**Check artifacts:**
```bash
ls docs/planning/tasks/      # Task files
ls docs/sprints/             # Sprint files
ls src/                      # Generated code
```

---

## Monitoring

### While Sprint Runs

**Check status every 30-60 minutes:**
```bash
/sprint status SPRINT-001
```

**Normal behavior:**
- Tasks complete after 1-3 iterations
- 70% complete with T1 only (Haiku)
- 30% escalate to T2 (Sonnet) for complex scenarios
- Takes 2-6 hours per task depending on complexity
- Some tasks run in parallel

**Warning signs:**
- Task on iteration 4+ (might need guidance)
- Task stuck on same agent >2 hours (check logs)
- Validation keeps failing on same criteria (requirements issue)

### If Task Fails

**After 5 iterations, task fails. Options:**

**1. Provide Guidance (Recommended):**
```bash
# Review validation report
/task validation TASK-001

# Provide specific guidance
"For TASK-001, the issue is [specific problem]. 
 Fix it by [specific solution]."

# Retry
/task retry TASK-001
```

**2. Split Task:**
```bash
"Split TASK-001 into:
 TASK-001A: [simpler first part]
 TASK-001B: [complex second part]
 
Update sprint accordingly."
```

**3. Skip (Last Resort):**
```bash
/task skip TASK-001 --create-debt-ticket
```

---

## After Sprint

### Review Results

**Check sprint summary:**
```
docs/sprints/SPRINT-001-summary.md
```

**Includes:**
- All tasks completed
- Iteration statistics
- T1/T2 tier usage breakdown
- Quality metrics
- Lessons learned

**Verify deliverables:**
```bash
# Run tests
pytest  # Python
npm test  # TypeScript

# Check coverage
coverage report  # Python  
npm run coverage  # TypeScript

# Review code
# Check src/ for generated code
# Review tests/ for test coverage
# Read docs/ for documentation
```

### Start Next Sprint

```bash
/sprint execute SPRINT-002
```

---

## Commands Cheat Sheet

### Available Slash Commands
```bash
/prd                      # Create PRD (Claude conducts interactive Q&A)
/planning                 # Generate tasks & sprints (Claude orchestrates agents)
/sprint SPRINT-001        # Execute sprint (Claude orchestrates all agents)
```

**Note:** These are the only 3 slash commands. They prompt Claude to manually orchestrate agents.

---

## Common Patterns

### Typical First Sprint

**Sprint 1: Foundation**
- Duration: 1-2 weeks
- Tasks: 5-8
- Focus: Database, authentication, CI/CD
- Iterations: 1-2 per task
- Time: 1-2 days automated execution
- T1 usage: 80% (most foundation work is straightforward)

**What you'll have:**
- ✅ Database schema and models
- ✅ User authentication working
- ✅ Basic API structure
- ✅ CI/CD pipeline
- ✅ Tests with >80% coverage
- ✅ Documentation

### Typical Iteration Pattern

**Iteration 1 (T1):**
- All agents run (full workflow) using T1 (Haiku)
- Validation finds gaps
- Most common: test coverage, error handling

**Iteration 2 (T1):**
- Only relevant agents re-run, still using T1
- Address specific gaps
- 70% of tasks pass validation here

**Iteration 3+ (T2 if needed):**
- Complex scenarios that T1 couldn't resolve
- T2 (Sonnet) agents take over
- Enhanced reasoning for edge cases
- Better handling of complex business logic
- 30% of tasks need this level

### T1→T2 Quality Escalation

**Iteration 1 (T1):**
- Haiku developers implement
- Cost-optimized first attempt

**Iteration 2 (T1):**
- Haiku developers fix gaps
- Straightforward corrections

**Iteration 3+ (T2):**
- Sonnet developers take over
- Complex problem solving
- Higher quality reasoning

### Typical Project Timeline

**Week 1:**
- Day 1: Planning (you) - 1 hour
- Day 1-2: Sprint 1 execution (automated) - foundation
- Day 2: Review sprint 1 - 1 hour

**Week 2:**
- Day 1: Sprint 2 execution (automated) - core features
- Day 2: Review sprint 2 - 1 hour

**Week 3:**
- Day 1: Sprint 3 execution (automated) - polish
- Day 2: Review sprint 3 - 1 hour
- Day 3: Deploy MVP

**Total:** 3 weeks, ~5 hours of your time, ~120 hours of automated work

---

## Tips for Success

### Planning Tips

**Be specific:**
- ✅ "User can login with email and password"
- ❌ "Authentication"

**Define success:**
- ✅ "API responds in <200ms"
- ❌ "Fast API"

**Know your integrations:**
- Determines tech stack
- Affects architecture
- Impacts timeline

**Set boundaries:**
- Define what's out of scope
- Prevents scope creep
- Keeps focused

### Execution Tips

**Trust iterations:**
- 1-3 iterations is normal
- Quality gates are working
- Don't intervene too early

**Trust T1→T2 escalation:**
- T1 handles most work cost-effectively
- T2 kicks in for complex scenarios
- Automatic switching works well

**Monitor, don't micromanage:**
- Check every 30-60 minutes
- Let system work
- Intervene only if stuck

**Review validations:**
- Read validation reports
- Understand why things failed
- Learn for future planning

**Maintain momentum:**
- Start next sprint immediately
- Don't wait days between sprints
- Keep system working

### Quality Tips

**Don't lower standards:**
- 80% test coverage minimum
- Security review mandatory
- Documentation required

**Address debt immediately:**
- Don't skip tasks without good reason
- Plan debt paydown in next sprint
- Track with proper tickets

**Celebrate quality:**
- Tasks passing on iteration 1
- High percentage of T1-only completions
- High test coverage
- Clean security audits

**Learn from tier usage:**
- Which tasks needed T2?
- Can requirements be clearer?
- Are task sizes appropriate?

---

## Troubleshooting

### "Planning takes too long"

**Expected:** 10-15 minutes for PRD Q&A  
**Solution:** Have answers prepared beforehand

### "Too many iterations"

**Expected:** 1-3 iterations per task  
**Problem:** 4+ iterations  
**Solution:**
- Review validation reports
- Tasks might be too large
- Requirements might be unclear
- Provide specific guidance

### "Too many T2 escalations"

**Expected:** 30% of tasks need T2  
**Problem:** >50% need T2  
**Solution:**
- Review task complexity
- Split complex tasks earlier
- Improve acceptance criteria clarity
- More specific requirements

### "Task failed after 5 iterations"

**Problem:** Task complexity too high  
**Solution:**
- Review failure details
- Provide specific guidance, OR
- Split into smaller tasks
- Don't skip unless non-critical

### "Sprint is stuck"

**Problem:** Blocking task failed  
**Solution:**
- Identify blocker with `/sprint status`
- Review blocker's failure
- Resolve blocker first
- Resume sprint

### "Don't know what's happening"

**Problem:** Lack of visibility  
**Solution:**
- Use `/sprint status` for overview
- Use `/task status` for details
- Read execution logs in `docs/`
- Review validation reports

---

## What You'll Get

### Per Task
- ✅ Working code (database + API + frontend or Python utilities)
- ✅ Tests with >80% coverage
- ✅ Security audit report
- ✅ Complete documentation

### Per Sprint
- ✅ All features working
- ✅ All tests passing
- ✅ All security reviews clean
- ✅ Production-ready deliverables
- ✅ Tier usage statistics

### Full Project
- ✅ Complete MVP
- ✅ All features tested
- ✅ Security audited
- ✅ Performance optimized
- ✅ Fully documented
- ✅ Ready to deploy
- ✅ Cost-optimized execution

---

## Cost Optimization

### T1/T2 System Benefits

**70% of work with T1 (Haiku):**
- Straightforward implementations
- Standard patterns
- Simple fixes
- Cost-effective

**30% of work with T2 (Sonnet):**
- Complex business logic
- Edge case handling
- Performance optimization
- Enhanced quality

**Result:**
- 60% cost savings vs all-Sonnet
- Same quality outcomes
- Automatic escalation
- No manual intervention needed

---

## Next Steps

**Right now:**
1. Run `/prd` in Claude Code
2. Answer questions (15 min)
3. Run `/planning`
4. Run `/sprint SPRINT-001`
5. Monitor Claude's orchestration
6. Review tier usage patterns

**For more details:**
- **[README.md](README.md)** - System overview
- **[docs/usage/USAGE.md](docs/usage/USAGE.md)** - Complete usage guide
- **[docs/usage/WORKFLOWS.md](docs/usage/WORKFLOWS.md)** - Orchestration patterns
- **[docs/usage/SETUP.md](docs/usage/SETUP.md)** - Template reference

**Start building!**
