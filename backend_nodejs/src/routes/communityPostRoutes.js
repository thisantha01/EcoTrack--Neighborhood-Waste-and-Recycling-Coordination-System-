const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  getPosts,
  createPost,
  toggleLike,
  addComment,
  deletePost,
} = require('../controllers/communityPostController');

const router = express.Router();

router.get('/', protect, getPosts);
router.post('/', protect, createPost);
router.post('/:id/like', protect, toggleLike);
router.post('/:id/comments', protect, addComment);
router.delete('/:id', protect, deletePost);

module.exports = router;
