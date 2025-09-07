import { createClient } from 'redis';

let redisClient;

export const connectRedis = async () => {
  try {
    redisClient = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379',
    });

    redisClient.on('error', (err) => {
      console.error('❌ Redis Client Error:', err);
    });

    redisClient.on('connect', () => {
      console.log('🔴 Redis connected');
    });

    redisClient.on('ready', () => {
      console.log('🔴 Redis ready');
    });

    redisClient.on('end', () => {
      console.log('🔴 Redis connection ended');
    });

    await redisClient.connect();
  } catch (error) {
    console.error('❌ Error connecting to Redis:', error.message);
    // Don't exit process for Redis errors, app can work without it
  }
};

export const getRedisClient = () => {
  return redisClient;
};

// Helper functions for common Redis operations
export const setCache = async (key, value, expiration = 3600) => {
  try {
    if (!redisClient?.isOpen) return false;
    await redisClient.setEx(key, expiration, JSON.stringify(value));
    return true;
  } catch (error) {
    console.error('Redis set error:', error);
    return false;
  }
};

export const getCache = async (key) => {
  try {
    if (!redisClient?.isOpen) return null;
    const value = await redisClient.get(key);
    return value ? JSON.parse(value) : null;
  } catch (error) {
    console.error('Redis get error:', error);
    return null;
  }
};

export const deleteCache = async (key) => {
  try {
    if (!redisClient?.isOpen) return false;
    await redisClient.del(key);
    return true;
  } catch (error) {
    console.error('Redis delete error:', error);
    return false;
  }
};

export const setUserOnline = async (userId) => {
  try {
    if (!redisClient?.isOpen) return false;
    await redisClient.setEx(`user:${userId}:online`, 300, 'true'); // 5 minutes
    return true;
  } catch (error) {
    console.error('Redis setUserOnline error:', error);
    return false;
  }
};

export const isUserOnline = async (userId) => {
  try {
    if (!redisClient?.isOpen) return false;
    const online = await redisClient.get(`user:${userId}:online`);
    return online === 'true';
  } catch (error) {
    console.error('Redis isUserOnline error:', error);
    return false;
  }
};
