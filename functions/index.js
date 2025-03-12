const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest, HttpsOptions } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const axios = require('axios');
const cheerio = require('cheerio');
const { logger } = require('firebase-functions/v2');

admin.initializeApp();

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
          if (label.includes('活動時間')) event.date = value;
          else if (label.includes('活動會場')) event.location = value;
          else if (label.includes('活動內容')) event.content = value;
          else if (label.includes('主辦單位')) event.organizer = value;
        });

        event.updateDate = $(elem).find('.update_date').text().trim() || '';
        event.id = eventId;
        events.push({ id: eventId, data: event });
      } catch (error) {
        logger.warn(`解析第 ${i + 1} 個活動時發生錯誤:`, error);
      }
    });

    if (events.length === 0) {
      throw new Error('No events found');
    }

    logger.info(`解析完成，找到 ${events.length} 個活動`);

    const batch = admin.firestore().batch();
    events.forEach((event) => {
      const docRef = admin.firestore().collection('events').doc(event.id);
      batch.set(docRef, event.data);
    });

    await batch.commit();
    logger.info(`成功儲存 ${events.length} 筆活動資料到 Firestore`);

    return { success: true, message: `儲存 ${events.length} 筆資料` };
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