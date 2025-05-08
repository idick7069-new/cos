const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest, HttpsOptions } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const axios = require('axios');
const cheerio = require('cheerio');
const { logger } = require('firebase-functions/v2');
const { Storage } = require('@google-cloud/storage');
const path = require('path');

admin.initializeApp();
const storage = new Storage();
const bucketName = 'cos-connect.firebasestorage.app'; // ✅ 是字串
const bucket = storage.bucket(bucketName); // ✅ 是 Bucket 物件

// 解析時間字串函數
function parseEventDate(dateStr) {
  try {
    // 移除多餘空格
    dateStr = dateStr.trim();

    // 處理日期範圍，用 ~ 分割
    let [startDate, endDate] = dateStr.split('~').map(d => d.trim());

    // 如果沒有結束日期，則與開始日期相同
    if (!endDate) {
      endDate = startDate;
    }

    // 轉換日期格式
    const formatDate = (dateStr) => {
      if (!dateStr) return null;

      // 匹配 YYYY-MM-DD(週) 格式，取出年月日
      const match = dateStr.match(/^(\d{4})-(\d{2})-(\d{2})/);
      if (match) {
        const [_, year, month, day] = match;
        return `${year}/${month}/${day}`;
      }
      return null;
    };

    const start = formatDate(startDate);
    const end = formatDate(endDate);

    // 生成活動天數陣列
    const days = [];
    if (start && end) {
      const startDateTime = new Date(start);
      const endDateTime = new Date(end);
      const currentDate = new Date(startDateTime);

      while (currentDate <= endDateTime) {
        days.push(
          `${currentDate.getFullYear()}/${String(currentDate.getMonth() + 1).padStart(2, '0')}/${String(currentDate.getDate()).padStart(2, '0')}`
        );
        currentDate.setDate(currentDate.getDate() + 1);
      }
    }

    return {
      startDate: start,
      endDate: end,
      days: days
    };
  } catch (error) {
    logger.warn('解析時間失敗:', error);
    return { startDate: null, endDate: null, days: [] };
  }
}

async function uploadImageToStorage(imageUrl, eventId) {
  try {
    if (!imageUrl) return '';
    if (!imageUrl.startsWith('http')) imageUrl = 'https:' + imageUrl;
    const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
    const buffer = Buffer.from(response.data, 'binary');
    const ext = path.extname(imageUrl.split('?')[0]) || '.png';
    const fileName = `events/${eventId}${ext}`;
    const file = bucket.file(fileName);
    await file.save(buffer, { contentType: response.headers['content-type'] });
    await file.makePublic();
    return `https://storage.googleapis.com/${bucketName}/${fileName}`;
  } catch (e) {
    logger.warn('圖片上傳失敗:', e);
    return '';
  }
}

async function runScraper() {
  try {
    logger.info('開始執行爬蟲');
    const url = 'https://www.doujin.com.tw/events/alist';
    const response = await axios.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      },
      timeout: 30000
    });

    if (!response.data) {
      throw new Error('No data received from the website');
    }

    logger.info('成功獲取網頁內容');
    const $ = cheerio.load(response.data);
    const events = [];

    $('.event_smi_info').each((i, elem) => {
      try {
        const event = {};
        const href = $(elem).find('.event_img a').attr('href') || '';
        const eventId = href.split('/events/info/')[1] || `unknown_${i}`;

        event.image = $(elem).find('.event_img img').attr('src') || '';
        event.title = $(elem).find('.list_smi_title a').text().trim() || '';
        event.type = $(elem).find('.list_smi_title .etype1').text().trim() || '';

        $(elem).find('.list_smi_lsit li').each((j, li) => {
          const label = $(li).find('.label').text().trim();
          const value = $(li).text().replace(label, '').trim();
          if (label.includes('活動時間')) {
            event.date = value; // 保留原始時間字串
            const { startDate, endDate, days } = parseEventDate(value);
            event.startDate = startDate;
            event.endDate = endDate;
            event.days = days;
          }
          else if (label.includes('活動會場')) event.location = value;
          else if (label.includes('活動內容')) event.content = value;
          else if (label.includes('主辦單位')) event.organizer = value;
        });

        event.updateDate = $(elem).find('.update_date').text().trim() || '';
        event.id = eventId;
        event.url = `https://www.doujin.com.tw/events/info/${eventId}`;
        events.push({ id: eventId, data: event });
      } catch (error) {
        logger.warn(`解析第 ${i + 1} 個活動時發生錯誤:`, error);
      }
    });

    if (events.length === 0) {
      throw new Error('No events found');
    }

    logger.info(`解析完成，找到 ${events.length} 個活動`);

    // 上傳所有圖片並取得 Storage 連結
    for (const event of events) {
      event.data.imageUrl = await uploadImageToStorage(event.data.image, event.id);
      delete event.data.image;
    }

    // 獲取現有的活動資料
    const existingEvents = await Promise.all(
      events.map(async (event) => {
        const doc = await admin.firestore().collection('events').doc(event.id).get();
        return { id: event.id, exists: doc.exists };
      })
    );

    // 過濾出需要新增的活動
    const newEvents = events.filter(event =>
      !existingEvents.find(existing => existing.id === event.id && existing.exists)
    );

    if (newEvents.length === 0) {
      logger.info('沒有新的活動需要新增');
      return { success: true, message: '沒有新的活動需要新增' };
    }

    // 使用批次寫入新增活動
    const batch = admin.firestore().batch();
    newEvents.forEach((event) => {
      const docRef = admin.firestore().collection('events').doc(event.id);
      batch.set(docRef, event.data);
    });

    await batch.commit();
    logger.info(`成功新增 ${newEvents.length} 筆新活動資料到 Firestore`);

    return {
      success: true,
      message: `新增 ${newEvents.length} 筆新資料，共掃描 ${events.length} 筆資料`
    };
  } catch (error) {
    logger.error('爬蟲執行失敗:', error);
    throw new Error(`爬蟲失敗: ${error.message}`);
  }
}

// 自動排程觸發（每天台灣時間 08:00）
exports.scrapeEventsScheduled = onSchedule(
  {
    schedule: '0 8 * * *',
    timeZone: 'Asia/Taipei',
    retryConfig: { retryCount: 3 },
    timeoutSeconds: 300,
    memory: '1GiB',
    region: 'us-central1'
  },
  async (event) => {
    try {
      await runScraper();
      return null;
    } catch (error) {
      logger.error('排程任務失敗:', error);
      throw error;
    }
  }
);

// 手動觸發（HTTP 請求）
exports.scrapeEventsManual = onRequest(
  {
    timeoutSeconds: 300,
    cors: {
      origin: true,
      methods: ['GET', 'POST'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      maxAge: 3600
    },
    maxInstances: 10,
    memory: '1GiB',
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: false,
    ingressSettings: 'ALLOW_ALL'
  },
  async (req, res) => {
    try {
      // 允許預檢請求
      if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET, POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        res.set('Access-Control-Max-Age', '3600');
        res.status(204).send('');
        return;
      }

      const result = await runScraper();
      res.status(200).json(result);
    } catch (error) {
      logger.error('手動觸發失敗:', error);
      res.status(500).json({
        success: false,
        message: '爬蟲失敗',
        error: error.message
      });
    }
  }
);