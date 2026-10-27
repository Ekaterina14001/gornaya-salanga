UPDATE content_headliners
SET image_url = CASE sort_order
    WHEN 0 THEN 'https://www.salanga.ru/up/17/51a5c408d8-glavnayazima-02.jpg'
    WHEN 1 THEN 'https://www.salanga.ru/up/room/nomer-04.jpg'
    WHEN 2 THEN 'https://www.salanga.ru/yiiassets/easyimage/6/6917b199b8c40571210a89edf50a2b25.jpg'
    ELSE 'https://www.salanga.ru/up/17/51a5c408d8-glavnayazima-02.jpg'
END
WHERE is_active = TRUE AND (image_url IS NULL OR trim(image_url) = '');
