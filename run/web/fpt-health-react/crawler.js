const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');

const app = express();
const PORT = 5000;

app.use(cors());

app.get('/news', async (req, res) => {
    try {
        const response = await axios.get('https://www.medicalnewstoday.com/news');
        const html = response.data;
        const $ = cheerio.load(html);
        const articles = [];

        $('li.css-6x6b1i').each((index, element) => {
            if (index < 4) {
                const title = $(element).find('h2.css-6y2217.css-12no7hq').text();
                const link = $(element).find('a.css-aw4mqk').attr('href');
                const description = $(element).find('a.css-2fdibo').text();
                const image = $(element).find('lazy-image').attr('src');

                articles.push({ title, link, description, image });
            }
        });
        res.json(articles);
    } catch (error) {
        res.status(500).send('Error while fetching data');
    }
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
