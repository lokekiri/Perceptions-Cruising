// Perceptive Cruising Backend - Complete API
// Includes: Diagnostic feedback system + SMTM questions

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Database connection
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'perceptive_cruising',
    waitForConnections: true,
    connectionLimit: 10
});

// ============================================
// SCENARIOS MODULE - Diagnostic Feedback
// ============================================

// Get all scenarios (optionally filter by module)
app.get('/api/scenarios', async (req, res) => {
    try {
        const { module_type } = req.query;
        
        let query = 'SELECT * FROM scenarios';
        let params = [];
        
        if (module_type) {
            query += ' WHERE module_type = ?';
            params.push(module_type);
        }
        
        const [scenarios] = await pool.query(query, params);
        res.json(scenarios);
    } catch (error) {
        console.error('Error fetching scenarios:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Get scenario by ID
app.get('/api/scenarios/:id', async (req, res) => {
    try {
        const [scenarios] = await pool.query(
            'SELECT * FROM scenarios WHERE id = ?',
            [req.params.id]
        );
        
        if (scenarios.length === 0) {
            return res.status(404).json({ error: 'Scenario not found' });
        }
        
        res.json(scenarios[0]);
    } catch (error) {
        console.error('Error fetching scenario:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// THE CRITICAL ENDPOINT: Submit answer and get diagnostic feedback
app.post('/api/scenarios/:id/submit', async (req, res) => {
    const { scenario_id, selected_answer, user_id } = req.body;
    
    try {
        // 1. Get the scenario to check correct answer
        const [scenarios] = await pool.query(
            'SELECT correct_answer FROM scenarios WHERE id = ?',
            [scenario_id]
        );
        
        if (scenarios.length === 0) {
            return res.status(404).json({ error: 'Scenario not found' });
        }
        
        const correct_answer = scenarios[0].correct_answer;
        const is_correct = selected_answer === correct_answer;
        
        // 2. Get the SPECIFIC feedback for this answer choice
        // This is the magic - different feedback for different wrong answers
        const [feedbacks] = await pool.query(
            `SELECT 
                is_correct,
                misconception,
                feedback_text,
                correct_reasoning
             FROM feedback 
             WHERE scenario_id = ? AND answer_choice = ?`,
            [scenario_id, selected_answer]
        );
        
        if (feedbacks.length === 0) {
            return res.status(500).json({ 
                error: 'No feedback available for this answer choice' 
            });
        }
        
        const feedback = feedbacks[0];
        
        // 3. Store the attempt in the database
        const [result] = await pool.query(
            `INSERT INTO attempts 
             (user_id, scenario_id, selected_answer, is_correct, attempted_at) 
             VALUES (?, ?, ?, ?, NOW())`,
            [user_id || 1, scenario_id, selected_answer, is_correct]
        );
        
        const attempt_id = result.insertId;
        
        // 4. Get attempt history for this user/scenario
        const [attempts] = await pool.query(
            `SELECT COUNT(*) as attempt_count,
                    SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct_count
             FROM attempts
             WHERE user_id = ? AND scenario_id = ?`,
            [user_id || 1, scenario_id]
        );
        
        const attempt_count = attempts[0].attempt_count;
        const has_been_correct = attempts[0].correct_count > 0;
        
        // 5. Return comprehensive response
        res.json({
            attempt_id,
            is_correct,
            feedback: {
                text: feedback.feedback_text,
                misconception: feedback.misconception,
                correct_reasoning: feedback.correct_reasoning
            },
            attempt_info: {
                attempt_number: attempt_count,
                has_been_correct_before: has_been_correct
            },
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Error submitting answer:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get learning analytics for a scenario
app.get('/api/scenarios/:id/analytics', async (req, res) => {
    try {
        const scenario_id = req.params.id;
        
        // Get users who went wrong -> right on this scenario
        const [learners] = await pool.query(
            `SELECT 
                user_id,
                COUNT(*) as total_attempts,
                MIN(CASE WHEN is_correct = 0 THEN attempted_at END) as first_wrong,
                MIN(CASE WHEN is_correct = 1 THEN attempted_at END) as first_correct,
                TIMESTAMPDIFF(SECOND, 
                    MIN(CASE WHEN is_correct = 0 THEN attempted_at END),
                    MIN(CASE WHEN is_correct = 1 THEN attempted_at END)
                ) as time_to_learn_seconds
             FROM attempts
             WHERE scenario_id = ?
             GROUP BY user_id
             HAVING first_wrong IS NOT NULL 
                AND first_correct IS NOT NULL
                AND first_wrong < first_correct`,
            [scenario_id]
        );
        
        const total_learners = learners.length;
        const avg_learning_time = learners.length > 0 
            ? learners.reduce((sum, l) => sum + l.time_to_learn_seconds, 0) / learners.length 
            : 0;
        
        res.json({
            scenario_id,
            users_who_learned: total_learners,
            average_learning_time_seconds: Math.round(avg_learning_time),
            individual_learning_journeys: learners,
            interpretation: avg_learning_time >= 45 && avg_learning_time <= 120
                ? 'Users are reading feedback (45-120 second range indicates engagement)'
                : avg_learning_time < 45
                    ? 'Users may be clicking through too quickly'
                    : 'Users are spending significant time on feedback'
        });
        
    } catch (error) {
        console.error('Error fetching analytics:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============================================
// SHOW ME TELL ME MODULE
// ============================================

// Get all SMTM questions (optionally filter by type)
app.get('/api/smtm/questions', async (req, res) => {
    try {
        const { type } = req.query; // 'tell_me' or 'show_me'
        
        let query = 'SELECT * FROM smtm_questions';
        let params = [];
        
        if (type) {
            query += ' WHERE question_type = ?';
            params.push(type);
        }
        
        query += ' ORDER BY id';
        
        const [questions] = await pool.query(query, params);
        res.json(questions);
    } catch (error) {
        console.error('Error fetching SMTM questions:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Get specific SMTM question by ID
app.get('/api/smtm/questions/:id', async (req, res) => {
    try {
        const [questions] = await pool.query(
            'SELECT * FROM smtm_questions WHERE id = ?',
            [req.params.id]
        );
        
        if (questions.length === 0) {
            return res.status(404).json({ error: 'Question not found' });
        }
        
        res.json(questions[0]);
    } catch (error) {
        console.error('Error fetching question:', error);
        res.status(500).json({ error: 'Database error' });
    }
});

// Submit/reveal SMTM answer
app.post('/api/smtm/submit', async (req, res) => {
    const { question_id, user_answer, user_id } = req.body;
    
    try {
        // Get the correct answer
        const [questions] = await pool.query(
            'SELECT answer_text, question_type FROM smtm_questions WHERE id = ?',
            [question_id]
        );
        
        if (questions.length === 0) {
            return res.status(404).json({ error: 'Question not found' });
        }
        
        const correct_answer = questions[0].answer_text;
        const question_type = questions[0].question_type;
        
        // For SMTM, mark as "attempted" when they reveal the answer
        // (These are recall questions, not diagnostic learning)
        const is_correct = user_answer !== null && user_answer !== '';
        
        // Store attempt
        const [result] = await pool.query(
            `INSERT INTO smtm_attempts 
             (user_id, question_id, user_answer, is_correct, attempted_at) 
             VALUES (?, ?, ?, ?, NOW())`,
            [user_id || 1, question_id, user_answer, is_correct]
        );
        
        // Get attempt count for this question
        const [attempts] = await pool.query(
            `SELECT COUNT(*) as attempt_count
             FROM smtm_attempts
             WHERE user_id = ? AND question_id = ?`,
            [user_id || 1, question_id]
        );
        
        res.json({
            attempt_id: result.insertId,
            correct_answer,
            question_type,
            attempt_count: attempts[0].attempt_count,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('Error submitting SMTM answer:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get user's SMTM progress
app.get('/api/smtm/progress/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;
        
        // Get completed questions by type
        const [progress] = await pool.query(
            `SELECT 
                sq.question_type,
                COUNT(DISTINCT sq.id) as total_questions,
                COUNT(DISTINCT sa.question_id) as completed_questions
             FROM smtm_questions sq
             LEFT JOIN smtm_attempts sa ON sq.id = sa.question_id AND sa.user_id = ?
             GROUP BY sq.question_type`,
            [userId]
        );
        
        const result = {
            tell_me: {
                completed: 0,
                total: 0
            },
            show_me: {
                completed: 0,
                total: 0
            }
        };
        
        progress.forEach(p => {
            if (p.question_type === 'tell_me') {
                result.tell_me.total = p.total_questions;
                result.tell_me.completed = p.completed_questions;
            } else if (p.question_type === 'show_me') {
                result.show_me.total = p.total_questions;
                result.show_me.completed = p.completed_questions;
            }
        });
        
        res.json(result);
        
    } catch (error) {
        console.error('Error fetching SMTM progress:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get overall user progress (scenarios + SMTM)
app.get('/api/users/:userId/progress', async (req, res) => {
    try {
        const userId = req.params.userId;
        
        // Get scenarios progress by module
        const [scenariosProgress] = await pool.query(
            `SELECT 
                s.module_type,
                COUNT(DISTINCT s.id) as total_scenarios,
                COUNT(DISTINCT CASE WHEN a.is_correct = 1 THEN s.id END) as completed_scenarios
             FROM scenarios s
             LEFT JOIN attempts a ON s.id = a.scenario_id AND a.user_id = ?
             GROUP BY s.module_type`,
            [userId]
        );
        
        // Get SMTM progress
        const [smtmProgress] = await pool.query(
            `SELECT 
                sq.question_type,
                COUNT(DISTINCT sq.id) as total_questions,
                COUNT(DISTINCT sa.question_id) as completed_questions
             FROM smtm_questions sq
             LEFT JOIN smtm_attempts sa ON sq.id = sa.question_id AND sa.user_id = ?
             GROUP BY sq.question_type`,
            [userId]
        );
        
        res.json({
            scenarios: scenariosProgress,
            smtm: smtmProgress,
            user_id: userId
        });
        
    } catch (error) {
        console.error('Error fetching user progress:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============================================
// GENERAL ENDPOINTS
// ============================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        service: 'perceptive-cruising-api',
        modules: ['scenarios', 'smtm']
    });
});

// Get dashboard data for a user
app.get('/api/dashboard/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;
        
        // Get all progress in one query-efficient call
        const [scenariosCount] = await pool.query(
            `SELECT 
                COUNT(DISTINCT s.id) as total,
                COUNT(DISTINCT CASE WHEN a.is_correct = 1 THEN s.id END) as completed
             FROM scenarios s
             LEFT JOIN attempts a ON s.id = a.scenario_id AND a.user_id = ?`,
            [userId]
        );
        
        const [smtmCount] = await pool.query(
            `SELECT 
                COUNT(DISTINCT sq.id) as total,
                COUNT(DISTINCT sa.question_id) as completed
             FROM smtm_questions sq
             LEFT JOIN smtm_attempts sa ON sq.id = sa.question_id AND sa.user_id = ?`,
            [userId]
        );
        
        // Get most recent activity
        const [recentActivity] = await pool.query(
            `(SELECT 'scenario' as type, scenario_id as id, attempted_at 
              FROM attempts WHERE user_id = ? ORDER BY attempted_at DESC LIMIT 5)
             UNION ALL
             (SELECT 'smtm' as type, question_id as id, attempted_at 
              FROM smtm_attempts WHERE user_id = ? ORDER BY attempted_at DESC LIMIT 5)
             ORDER BY attempted_at DESC LIMIT 5`,
            [userId, userId]
        );
        
        res.json({
            scenarios: {
                total: scenariosCount[0].total,
                completed: scenariosCount[0].completed
            },
            smtm: {
                total: smtmCount[0].total,
                completed: smtmCount[0].completed
            },
            recent_activity: recentActivity
        });
        
    } catch (error) {
        console.error('Error fetching dashboard:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Perceptive Cruising API running on port ${PORT}`);
    console.log('Modules: Diagnostic feedback + Show Me Tell Me');
    console.log('Ready for testing');
});