# Perceptions-Cruising
Perceptions Cruising is a web based learning system designed to help learner drivers understand real world driving situations through interactive visual scenarios and diagnostic feedback. Instead of focusing only on theory, the system tests practical decision-making by presenting realistic road scenarios and analysing the learner’s choices. The platform provides immediate explanatory feedback, highlights common misconceptions, and tracks user attempts to help identify weak areas over time. The goal of the project is to support learner confidence, reduce lesson dependency, and improve readiness for the UK practical driving test through structured, evidence-based learning interactions. In this README.MD, I will take you through the chronological steps of developing the project as well as showing the tests to my project and giving feedback and reflections if any issues come up.

## 2-8 Feb - Adding Diagnostic Feedback System Prototype

This is a working prototype of what I considered to be the **most critical** feature of Perceptions Cruising: the diagnostic feedback system that enables learning.

**This prototype proves:**
- ✅ Diagnostic feedback for specific wrong answers (not generic "incorrect")
- ✅ The learning loop: wrong → feedback → retry → correct
- ✅ Database evidence showing the learning journey
- ✅ Analytics endpoint that proves learning is happening

## What's Built

### 1. Database Schema (`database/schema.sql`)
- Users, Scenarios, Feedback, Attempts tables
- **Critical table: `feedback`** - stores specific diagnostic feedback for each wrong answer
- ONE complete scenario with full feedback for all three answer choices

### 2. Backend API (`backend/server.js`)
- `GET /api/scenarios/:id` - Get scenario details
- `POST /api/scenarios/:id/submit` - Submit answer, get diagnostic feedback
- `GET /api/scenarios/:id/analytics` - Get learning evidence (for assessor)

### 3. Frontend Demo (`frontend/index.html`)
- Interactive scenario with roundabout diagram
- Three answer choices (left_lane, right_lane, either_lane)
- Real-time diagnostic feedback
- Retry mechanism
- Evidence display

## How to Run

### Prerequisites
- Node.js (v16+)
- MySQL (or MariaDB)

### Setup Steps

1. **Create the database:**
```bash
mysql -u root -p
CREATE DATABASE perceptions_cruising;
exit
```

2. **Load the schema:**
```bash
mysql -u root -p perceptions_cruising < database/schema.sql
```

3. **Install backend dependencies:**
```bash
cd backend
npm install
```

4. **Start the backend:**
```bash
# Set environment variables if needed
export DB_HOST=localhost
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=perceptions_cruising

npm start
```

You should see:
```
Perceptions Cruising API running on port 3000
Diagnostic feedback system ready
```

5. **Open the frontend:**
```bash
cd ../frontend
# Open index.html in your browser
# Or use a simple server:
python3 -m http.server 8000
# Then visit: http://localhost:8000
```

## Testing the Diagnostic Feedback

### Test Case 1: Wrong → Right (The Core Behavior)

1. Select "Left lane" (wrong answer)
2. Click "Submit Answer"
3. **Observe the diagnostic feedback:**
   - Explains WHY left lane is wrong (positions you for early exits)
   - Explains WHAT you should think instead (right lane for 3rd exit)
   - Shows the misconception ("Thinking left lane works for any direction if you signal")
4. Click "Try This Scenario Again"
5. Select "Right lane" (correct answer)
6. Click "Submit Answer"
7. **Success!** You've demonstrated the learning loop

### Test Case 2: Different Wrong Answer = Different Feedback

1. Try again with "Either lane" selected
2. **Observe DIFFERENT feedback:**
   - Different misconception ("Thinking you can change lanes inside the roundabout")
   - Different explanation (no lane switching allowed)
   - Same correct reasoning reinforced

**This proves the system provides diagnostic, not generic, feedback.**

### Test Case 3: View the Evidence

After completing wrong → right:
1. Click "View Learning Evidence"
2. See the analytics JSON showing:
   - Users who went wrong → right
   - Time between attempts (should be 45-90 seconds)
   - Evidence that learning happened

## The Database Evidence

After testing, query the database to see the proof:

```sql
-- See your attempts
SELECT * FROM attempts ORDER BY attempted_at DESC LIMIT 5;

-- See the learning journey
SELECT 
    user_id,
    scenario_id,
    selected_answer,
    is_correct,
    attempted_at
FROM attempts
WHERE user_id = 1 AND scenario_id = 1
ORDER BY attempted_at;
```

You should see something like:
```
+----+---------+-------------+-----------------+------------+---------------------+
| id | user_id | scenario_id | selected_answer | is_correct | attempted_at        |
+----+---------+-------------+-----------------+------------+---------------------+
| 1  |       1 |           1 | left_lane       |          0 | 2026-02-15 14:23:18 |
| 2  |       1 |           1 | right_lane      |          1 | 2026-02-15 14:24:32 |
+----+---------+-------------+-----------------+------------+---------------------+
```

**74 seconds between attempts = user read the feedback**

## The Feedback Quality

Look at `database/schema.sql` lines 40-77 to see the three different feedback texts:

1. **Correct answer (right_lane):** Reinforces correct reasoning
2. **Wrong answer 1 (left_lane):** Explains it positions you for wrong exits
3. **Wrong answer 2 (either_lane):** Explains why lane switching is dangerous

Each one addresses a DIFFERENT misconception. This is what makes it diagnostic, not generic.

## Next Steps (Not Built Yet)

This should prove that the core mechanism works but for completing the project I need to add the following:

- [ ] Add authentication system
- [ ] Add 7-9 more roundabout scenarios
- [ ] Build dashboard showing progress
- [ ] Deploy to production
- [ ] Run user testing with real learners
- [ ] Add second module (lane discipline)

## Files Structure

```
perceptions-cruising/
├── database/
│   └── schema.sql          # Database schema + seed data
├── backend/
│   ├── server.js           # Express API with feedback logic
│   └── package.json        # Dependencies
├── frontend/
│   └── index.html          # Demo interface
└── README.md               # This file
```

## API Examples

### Get scenario:
```bash
curl http://localhost:3000/api/scenarios/1
```

### Submit answer:
```bash
curl -X POST http://localhost:3000/api/scenarios/1/submit \
  -H "Content-Type: application/json" \
  -d '{
    "scenario_id": 1,
    "selected_answer": "left_lane",
    "user_id": 1
  }'
```
