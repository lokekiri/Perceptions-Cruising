# Perceptive Cruising

**Practice the situations before you face them**

Perceptive Cruising is an interactive web application that helps UK learner drivers understand driving scenarios through visual diagrams and diagnostic feedback. The system focuses on roundabout lane positioning, junction observations, and DVSA Show Me Tell Me questions, providing learners with targeted practice and detailed explanations when they make mistakes.

---

## 📋 Table of Contents

- [What It Does](#what-it-does)
- [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Running the Application](#running-the-application)
- [Using the Application](#using-the-application)
- [File Structure](#file-structure)
- [Known Limitations](#known-limitations)
- [Future Work](#future-work)

---

## 🎯 What It Does

Perceptive Cruising is an educational web app for UK learner drivers that provides interactive practice for driving scenarios (roundabouts, junctions, narrow roads, pedestrian crossings, obstructions, and mirror checks) with diagnostic feedback that explains WHY wrong answers are wrong, plus a complete Show Me Tell Me practice and test mode covering all 21 DVSA questions.

---

## ✨ Core Features

### Driving Scenarios Module
- **6 interactive scenarios** covering common UK driving situations
- **Diagnostic feedback system** that identifies specific misconceptions
- **Visual diagrams** for each scenario
- **Wrong → Right learning loop** tracked via database timestamps
- **Multiple answer options** with detailed reasoning for each

### Show Me Tell Me Module
- **21 DVSA questions** (14 Tell Me + 7 Show Me)
- **Practice Mode**: Multiple choice quiz with instant feedback
- **Test Mode**: Realistic test simulation (1 Tell Me text input + 1 Show Me clickable diagram)
- **Interactive car diagrams** for Show Me questions
- **Bonnet photo** for engine check questions
- **Progress tracking** with completion statistics

### Technical Features
- **RESTful API** with Node.js/Express backend
- **MySQL database** with proper schema and foreign keys
- **Attempt tracking** for learning analytics
- **Responsive UI** with clean, modern design
- **Error handling** and validation throughout

---

## 🛠️ Tech Stack

**Backend:**
- Node.js (v14+)
- Express.js (v4.x)
- MySQL (v8.0+)
- mysql2 (Promise-based MySQL client)
- cors (Cross-origin resource sharing)

**Frontend:**
- Vanilla HTML5
- CSS3 (no frameworks)
- Vanilla JavaScript (ES6+)
- SVG for interactive diagrams

**Database:**
- MySQL 8.0

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

1. **Node.js** (v14.0.0 or higher)
   - Download: https://nodejs.org/
   - Verify: `node --version`

2. **MySQL** (v8.0 or higher)
   - Download: https://dev.mysql.com/downloads/mysql/
   - Verify: `mysql --version`

3. **Git** (optional, for cloning)
   - Download: https://git-scm.com/
   - Verify: `git --version`

4. **Code Editor** (recommended: VS Code)
   - Download: https://code.visualstudio.com/

---

## 🚀 Installation & Setup

### Step 1: Get the Project Files

Create a project directory and organize files:

```bash
mkdir perceptive-cruising
cd perceptive-cruising
```

Your directory structure should be:

```
perceptive-cruising/
├── backend/
│   ├── server.js
│   ├── package.json
│   └── node_modules/
├── frontend/
│   ├── index.html
│   ├── scenarios.html
│   ├── smtm.html
│   ├── smtm-test.html
│   └── bonnet.jpg
└── database/
    └── schema.sql
```

### Step 2: Set Up the Database

1. **Start MySQL:**
   ```bash
   # On macOS with Homebrew
   brew services start mysql
   
   # On Windows (from MySQL installation directory)
   mysqld.exe
   
   # On Linux
   sudo systemctl start mysql
   ```

2. **Log into MySQL:**
   ```bash
   mysql -u root -p
   ```
   Enter your MySQL root password when prompted.

3. **Create the database:**
   ```sql
   CREATE DATABASE perceptive_cruising;
   USE perceptive_cruising;
   ```

4. **Import the schema:**
   ```sql
   SOURCE /path/to/your/database/schema.sql;
   ```
   
   **OR** from terminal:
   ```bash
   mysql -u root -p perceptive_cruising < database/schema.sql
   ```

5. **Verify the setup:**
   ```sql
   SHOW TABLES;
   ```
   
   You should see:
   ```
   +--------------------------------+
   | Tables_in_perceptive_cruising |
   +--------------------------------+
   | attempts                      |
   | feedback                      |
   | scenarios                     |
   | smtm_attempts                 |
   | smtm_questions                |
   | users                         |
   +--------------------------------+
   ```

6. **Check seeded data:**
   ```sql
   SELECT COUNT(*) FROM scenarios;      -- Should return 6
   SELECT COUNT(*) FROM feedback;       -- Should return 18
   SELECT COUNT(*) FROM smtm_questions; -- Should return 21
   ```

### Step 3: Set Up the Backend

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create package.json** (if not already present):
   ```bash
   npm init -y
   ```

3. **Install dependencies:**
   ```bash
   npm install express mysql2 cors
   ```

4. **Verify package.json includes:**
   ```json
   {
     "dependencies": {
       "express": "^4.18.0",
       "mysql2": "^3.0.0",
       "cors": "^2.8.5"
     }
   }
   ```

5. **Configure database connection in server.js:**
   
   Open `server.js` and ensure the database configuration matches your MySQL setup:
   ```javascript
   const pool = mysql.createPool({
       host: 'localhost',
       user: 'root',              // Change if different
       password: 'your_password', // Change to your MySQL password
       database: 'perceptive_cruising',
       waitForConnections: true,
       connectionLimit: 10,
       queueLimit: 0
   });
   ```

### Step 4: Set Up the Frontend

1. **Navigate to frontend directory:**
   ```bash
   cd ../frontend
   ```

2. **Ensure all HTML files are present:**
   - `index.html` (homepage)
   - `scenarios.html` (driving scenarios)
   - `smtm.html` (practice mode)
   - `smtm-test.html` (test mode)
   - `bonnet.jpg` (engine bay photo)

3. **Verify API URL in all HTML files:**
   
   Each HTML file should have:
   ```javascript
   const API_URL = 'http://localhost:3000/api';
   ```
   
   Check this in:
   - `scenarios.html` (around line 420)
   - `smtm.html` (around line 380)
   - `smtm-test.html` (around line 430)

---

## ▶️ Running the Application

### Terminal 1: Start the Backend

```bash
cd backend
npm start
```

**Expected output:**
```
Server running on port 3000
Database connected successfully
```

**If you see an error:**
- Check MySQL is running: `mysql -u root -p`
- Verify database exists: `SHOW DATABASES;`
- Check credentials in `server.js`

### Terminal 2: Start the Frontend

```bash
cd frontend
python3 -m http.server 8000
```

**OR** with Python 2:
```bash
python -m SimpleHTTPServer 8000
```

**OR** with Node.js http-server:
```bash
npm install -g http-server
http-server -p 8000
```

**Expected output:**
```
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

### Access the Application

Open your browser and navigate to:
- **Homepage:** http://localhost:8000/index.html
- **Scenarios:** http://localhost:8000/scenarios.html
- **SMTM Practice:** http://localhost:8000/smtm.html
- **SMTM Test:** http://localhost:8000/smtm-test.html

---

## 👤 Using the Application

### Test User Credentials

The database is pre-seeded with a test user:
- **Email:** test@example.com
- **Password:** Not implemented (authentication not built yet)
- **User ID:** 1 (hardcoded in frontend for testing)

**Note:** User authentication is not implemented. The frontend currently uses `USER_ID = 1` for all interactions.

### Sample Workflow

#### Driving Scenarios Module:

1. **Visit:** http://localhost:8000/scenarios.html
2. **Select a scenario:** Click any of the 6 scenario buttons
3. **Read the question:** Understand the driving situation
4. **Choose an answer:** Click one of the 3 radio button options
5. **Submit:** Click "Submit Answer"
6. **Read feedback:** 
   - If correct: See success message
   - If wrong: Read diagnostic feedback explaining the misconception
7. **Try again:** Click "Try Again" to retry or "Next Scenario" to continue

#### SMTM Practice Mode:

1. **Visit:** http://localhost:8000/smtm.html
2. **Choose question type:** Click "Tell Me Questions" or "Show Me Questions"
3. **Answer the question:** Select from 3 multiple choice options
4. **Check answer:** Click "Check Answer"
5. **Review:** See correct answer highlighted in green
6. **Navigate:** Use Previous/Next/Random buttons

#### SMTM Test Mode:

1. **Visit:** http://localhost:8000/smtm-test.html
2. **Start test:** Click "Begin Test"
3. **Tell Me question:** Type your answer from memory
4. **Show Me question:** Click the correct car control on the diagram
5. **See results:** View your score (0-2) and detailed feedback
6. **Retry:** Click "Take Another Test" for new random questions

---

## 📂 File Structure

```
perceptive-cruising/
│
├── backend/
│   ├── server.js                 # Express API server
│   ├── package.json              # Node dependencies
│   └── node_modules/             # Installed packages
│
├── frontend/
│   ├── index.html                # Homepage with module cards
│   ├── scenarios.html            # 6 driving scenarios with diagnostic feedback
│   ├── smtm.html                 # Practice mode (21 questions, multiple choice)
│   ├── smtm-test.html            # Test mode (1 Tell Me + 1 Show Me)
│   └── bonnet.jpg                # Engine bay reference photo
│
└── database/
    └── schema.sql                # Complete database schema with seed data
```

---

## ⚠️ Known Limitations

### Authentication & User Management
- **No login system:** User authentication is not implemented
- **Hardcoded user ID:** Frontend uses `USER_ID = 1` for all interactions
- **No user registration:** Cannot create new accounts
- **No password hashing:** Test user has placeholder password hash

### Scenarios Module
- **Limited scenario types:** Only 6 scenarios available (not a comprehensive driving course)
- **Static diagrams:** Diagrams are placeholders (referenced as .png files that don't exist)
- **No image hosting:** Scenario diagrams need to be created and added
- **No scenario progression:** No guided learning path through scenarios
- **No difficulty levels:** All scenarios treated equally

### SMTM Module
- **Basic car diagram:** SVG interior diagram is simplified (not photo-realistic)
- **Limited Show Me controls:** Only 7 controls represented on diagram
- **No bonnet diagram clickable:** Bonnet questions show photo but aren't clickable
- **Keyword matching:** Tell Me answer checking uses simple keyword matching (not AI-based)
- **No speech input:** Cannot record spoken answers (real test is verbal)

### Progress Tracking
- **No learning analytics dashboard:** Can't visualize learning progress over time
- **No spaced repetition:** Doesn't intelligently schedule question review
- **No weak area identification:** Doesn't highlight which scenarios need more practice
- **Basic completion tracking:** Only tracks if question was answered correctly once

### UI/UX
- **No mobile optimization:** Designed for desktop, may not work well on phones
- **Basic styling:** Functional but not highly polished
- **No dark mode:** Only light theme available
- **No accessibility features:** No screen reader support, keyboard navigation limited
- **No animations:** Static transitions between states

### Backend
- **No rate limiting:** API has no request throttling
- **No input validation:** Limited server-side validation of inputs
- **No error logging:** Basic console.log only, no proper logging system
- **No session management:** No JWT tokens or session handling
- **Single environment:** No development/production environment separation

### Testing
- **No automated tests:** No unit tests, integration tests, or E2E tests
- **No CI/CD pipeline:** No automated deployment or testing
- **Manual testing only:** Relies on manual verification

### Deployment
- **Local only:** Not configured for production deployment
- **No HTTPS:** Uses HTTP only (not secure for production)
- **No environment variables:** Credentials hardcoded in source
- **No Docker setup:** No containerization

### Content
- **UK specific only:** Focused on UK Highway Code and DVSA test
- **Limited scenarios:** Only covers 6 out of hundreds of possible driving situations
- **No video content:** Text and diagrams only, no instructional videos
- **No examiner feedback simulation:** Doesn't replicate real examiner interaction style

---

## 🔮 Future Work

### High Priority
- [ ] Implement user authentication (login/logout)
- [ ] Create actual scenario diagrams (replace placeholder .png references)
- [ ] Add more driving scenarios (expand beyond 6)
- [ ] Improve Tell Me answer checking (use NLP or more sophisticated matching)
- [ ] Mobile responsive design
- [ ] Add scenario progression system (beginner → intermediate → advanced)

### Medium Priority
- [ ] Learning analytics dashboard
- [ ] Spaced repetition algorithm
- [ ] Export progress reports
- [ ] Instructor view (for driving schools)
- [ ] Create clickable bonnet diagram for Show Me questions
- [ ] Add more realistic car interior diagram
- [ ] Sound effects and audio feedback
- [ ] Achievement/badge system

### Low Priority
- [ ] Dark mode
- [ ] Multiple language support
- [ ] Social features (compare scores with friends)
- [ ] Video explanations for scenarios
- [ ] AI tutor chatbot
- [ ] Integration with driving lesson booking systems

---

## 🐛 Troubleshooting

### Backend won't start

**Error:** `Error: connect ECONNREFUSED`
- **Cause:** MySQL not running or wrong credentials
- **Fix:** 
  ```bash
  mysql -u root -p  # Check MySQL is running
  ```
  Verify credentials in `server.js`

**Error:** `Error: ER_BAD_DB_ERROR: Unknown database`
- **Cause:** Database not created
- **Fix:**
  ```sql
  CREATE DATABASE perceptive_cruising;
  SOURCE schema.sql;
  ```

**Error:** `Cannot find module 'express'`
- **Cause:** Dependencies not installed
- **Fix:**
  ```bash
  cd backend
  npm install
  ```

### Frontend shows errors

**Error:** `Failed to fetch` in browser console
- **Cause:** Backend not running
- **Fix:** Start backend with `npm start` from `/backend` directory

**Error:** `404 Not Found` for scenarios
- **Cause:** Database not seeded
- **Fix:** Run `SOURCE schema.sql` in MySQL

**Error:** `bonnet.jpg not found`
- **Cause:** Image file missing or wrong path
- **Fix:** Ensure `bonnet.jpg` is in `/frontend` directory

### Database issues

**Error:** Scenarios show "Scenario not found"
- **Cause:** Database not properly seeded
- **Fix:**
  ```sql
  SELECT COUNT(*) FROM scenarios;  -- Should be 6
  SELECT COUNT(*) FROM feedback;   -- Should be 18
  ```
  If counts are wrong, re-run schema.sql

**Error:** SMTM questions not loading
- **Cause:** SMTM questions not seeded
- **Fix:**
  ```sql
  SELECT COUNT(*) FROM smtm_questions;  -- Should be 21
  ```
  If wrong, re-run schema.sql

---

## 📝 API Endpoints Reference

### Scenarios
- `GET /api/scenarios` - Get all scenarios
- `GET /api/scenarios/:id` - Get single scenario
- `POST /api/scenarios/:id/submit` - Submit answer and get feedback

### SMTM
- `GET /api/smtm/questions` - Get all SMTM questions (filter by type)
- `GET /api/smtm/questions/:id` - Get single question
- `POST /api/smtm/submit` - Submit answer
- `GET /api/smtm/progress/:userId` - Get user progress

### Dashboard
- `GET /api/users/:userId/progress` - Get overall progress
- `GET /api/dashboard/:userId` - Get dashboard data

---

## 📄 License

This project is for educational purposes as part of a university final year project.

---

## 👨‍💻 Author

Created by Montell (Student ID: lokel001)  
Goldsmiths, University of London  
Final Year Computing Project  
2025/2026

---

## 🙏 Acknowledgments

- DVSA (Driver and Vehicle Standards Agency) for official Show Me Tell Me questions
- UK Highway Code for driving scenario guidance
- Learner drivers and instructors who provided feedback

---

## 📧 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Verify all [Prerequisites](#prerequisites) are installed
3. Ensure you followed [Installation & Setup](#installation--setup) exactly
4. Check browser console for JavaScript errors (F12)
5. Check terminal for backend errors

---

**Remember:** This is a prototype/MVP focused on demonstrating the core diagnostic feedback mechanism. The goal is to show that wrong → right learning loops can be tracked via database timestamps, proving that learners read the feedback before retrying. Polish and feature completeness are secondary to this core educational insight.
