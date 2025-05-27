import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { List, ListItem, ListItemText, Typography, Modal, Box, TextField, Button } from '@mui/material';

const FeedbackListWithReply = ({ onClose }) => {
    const [feedbacks, setFeedbacks] = useState([]);
    const [selectedFeedback, setSelectedFeedback] = useState(null);
    const [replyContent, setReplyContent] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        axios.get('http://localhost:8080/api/v1/feedback/list')
            .then(response => {
                setFeedbacks(response.data);
            })
            .catch(error => {
                console.error('Error fetching feedbacks', error);
                setError('Error fetching feedbacks');
            });
    }, []);

    const handleReply = () => {
        const emailData = {
            name:selectedFeedback.name,
            email: selectedFeedback.email,
            subject: `Re: ${selectedFeedback.subject}`,
            message: replyContent,
        };

        axios.post('http://localhost:8080/api/v1/feedback/reply', emailData)
            .then(response => {
                setSelectedFeedback(null);
                setReplyContent('');
                onClose();
            })
            .catch(error => {
                console.error('Error sending reply', error);
                setError('Error sending reply');
            });
    };

    return (
        <Modal
            open={true}
            onClose={onClose}
            aria-labelledby="modal-title"
            aria-describedby="modal-description"
        >
            <Box sx={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                width: '80%',
                bgcolor: 'background.paper',
                border: '2px solid #000',
                boxShadow: 24,
                p: 4,
                maxHeight: '80vh',
                overflowY: 'auto'
            }}>
                <Typography variant="h6" gutterBottom>
                    Feedbacks
                </Typography>
                {error && <Typography color="error">{error}</Typography>}
                <List>
                    {feedbacks.map(feedback => (
                        <ListItem key={feedback.id} button onClick={() => setSelectedFeedback(feedback)}>
                            <ListItemText
                                primary={`From: ${feedback.name} (${feedback.email})`}
                                secondary={`Subject: ${feedback.subject} - Message: ${feedback.message}`}
                            />
                        </ListItem>
                    ))}
                </List>
                {selectedFeedback && (
                    <Box sx={{ mt: 4 }}>
                        <Typography variant="h6">Reply: {selectedFeedback.email}</Typography>
                        <TextField
                            label="Message"
                            multiline
                            rows={4}
                            value={replyContent}
                            onChange={(e) => setReplyContent(e.target.value)}
                            fullWidth
                            sx={{ mt: 2 }}
                        />
                        <Box sx={{ mt: 2, display: 'flex', justifyContent: 'flex-end' }}>
                            <Button onClick={handleReply} variant="contained" color="primary">
                                Send
                            </Button>
                        </Box>
                    </Box>
                )}
            </Box>
        </Modal>
    );
};

export default FeedbackListWithReply;
