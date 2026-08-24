const CommunityPost = require('../models/CommunityPost');
const UserPoints = require('../models/UserPoints');


// Helper to award points
const awardPoints = async (userId, points, field) => {
  try {
    const update = { $inc: { points } };
    if (field) update.$inc[field] = 1;

    const userPoints = await UserPoints.findOneAndUpdate(
      { user: userId },
      update,
      { upsert: true, new: true }
    );

    // Update level
    let level = 'bronze';
    if (userPoints.points >= 500) level = 'platinum';
    else if (userPoints.points >= 200) level = 'gold';
    else if (userPoints.points >= 100) level = 'silver';

    await UserPoints.findOneAndUpdate(
      { user: userId },
      { level },
      { new: true }
    );
  } catch (err) {
    console.error('Award points error:', err);
  }
};


// =====================================================
// GET POSTS (Feed)
// =====================================================

const getPosts = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const posts = await CommunityPost.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('author', 'name profilePicture role')
      .populate('comments.user', 'name profilePicture');

    const total = await CommunityPost.countDocuments();

    return res.status(200).json({
      success: true,
      posts,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });

  } catch (error) {
    console.error('Get posts error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch posts',
    });
  }
};


// =====================================================
// CREATE POST
// =====================================================

const createPost = async (req, res) => {
  try {
    const { content, imageUrl, tags } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Post content is required',
      });
    }

    const post = await CommunityPost.create({
      author: req.user._id,
      content: content.trim(),
      imageUrl: imageUrl || null,
      tags: tags || [],
    });

    await post.populate('author', 'name profilePicture role');

    // Award points for creating post
    await awardPoints(req.user._id, 5, 'postsCreated');

    return res.status(201).json({
      success: true,
      message: 'Post created successfully',
      post,
    });

  } catch (error) {
    console.error('Create post error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to create post',
    });
  }
};


// =====================================================
// LIKE / UNLIKE POST
// =====================================================

const toggleLike = async (req, res) => {
  try {
    const post = await CommunityPost.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    const userId = req.user._id;
    const liked = post.likes.includes(userId);

    if (liked) {
      post.likes.pull(userId);
    } else {
      post.likes.push(userId);
    }

    await post.save();

    return res.status(200).json({
      success: true,
      liked: !liked,
      likesCount: post.likes.length,
    });

  } catch (error) {
    console.error('Toggle like error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to update like',
    });
  }
};


// =====================================================
// ADD COMMENT
// =====================================================

const addComment = async (req, res) => {
  try {
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Comment text is required',
      });
    }

    const post = await CommunityPost.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    post.comments.push({
      user: req.user._id,
      text: text.trim(),
    });

    await post.save();
    await post.populate('comments.user', 'name profilePicture');

    return res.status(201).json({
      success: true,
      comment: post.comments[post.comments.length - 1],
    });

  } catch (error) {
    console.error('Add comment error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to add comment',
    });
  }
};


// =====================================================
// DELETE POST
// =====================================================

const deletePost = async (req, res) => {
  try {
    const post = await CommunityPost.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    if (post.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorised to delete this post',
      });
    }

    await post.deleteOne();

    return res.status(200).json({
      success: true,
      message: 'Post deleted',
    });

  } catch (error) {
    console.error('Delete post error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to delete post',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getPosts,
  createPost,
  toggleLike,
  addComment,
  deletePost,
};
