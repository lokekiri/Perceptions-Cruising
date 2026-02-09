// Perceptions Cruising Backend - Diagnostic Feedback System
// This is the core: evaluating answers and returning specific feedback

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
    database: process.env.DB_NAME || 'perceptions_cruising',
    waitForConnections: true,
    connectionLimit: 10
});

// TEST ENDPOINT: Get scenario by ID
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
            // Fallback if no specific feedback exists (shouldn't happen in production)
            return res.status(500).json({ 
                error: 'No feedback available for this answer choice' 
            });
        }
        
        const feedback = feedbacks[0];
        
        // 3. Store the attempt in the database
        // This creates the evidence trail we showed in the viva
        const [result] = await pool.query(
            `INSERT INTO attempts 
             (user_id, scenario_id, selected_answer, is_correct, attempted_at) 
             VALUES (?, ?, ?, ?, NOW())`,
            [user_id || 1, scenario_id, selected_answer, is_correct]
        );
        
        const attempt_id = result.insertId;
        
        // 4. Get attempt history for this user/scenario
        // This tells us if it's their first attempt, second, etc.
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
                misconception: feedback.misconception, // Why they got it wrong
                correct_reasoning: feedback.correct_reasoning // What to think instead
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

// ANALYTICS ENDPOINT: Get learning evidence for a scenario
// This is what we show the assessor
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
        
        // Calculate statistics
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

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'perceptions-cruising-api' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Perceptions Cruising API running on port ${PORT}`);
    console.log('Diagnostic feedback system ready');
});
