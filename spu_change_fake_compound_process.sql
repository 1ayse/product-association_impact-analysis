-- skc daily spu data with previous day's spu using lag function
WITH flag_change AS (
    SELECT
        a.skc,
        a.dt,
        a.spu,
        LAG(a.spu) OVER (PARTITION BY a.skc ORDER BY a.dt) AS prev_spu
    FROM prod.skc_snapshot a
    JOIN prod.skc_master c 
        ON a.skc = c.skc
    WHERE a.dt >= '20250101'
),

-- association date is when the minimum date spu and previous spu are not the same
association_dt AS (
    SELECT
        skc,
        MIN(dt) AS association_dt
    FROM flag_change
    WHERE spu <> prev_spu
    GROUP BY skc
),

disassociation_dt AS (
    SELECT
        skc,
        MIN(dt) AS disassociation_dt
    FROM (
        SELECT
            a.skc,
            a.dt,
            a.multicolor_flag_2,
            LAG(a.multicolor_flag_2) OVER (
                PARTITION BY a.skc ORDER BY a.dt
            ) AS prev_flag
        FROM prod.spu_attr_snapshot a
        INNER JOIN prod.skc_master b
            ON a.skc = b.skc
        WHERE a.dt >= '20250701'
    ) a
    INNER JOIN association_dt b
        ON a.skc = b.skc
    WHERE prev_flag = 1 
      AND multicolor_flag = 0
    GROUP BY skc
),

skc_list AS (
    SELECT
        'P0' AS priority,
        'to be listed in 1 week' AS cate,
        a.skc,
        expected_listing_date AS frst_sale_time,
        a.new_cate_1_nm,
        a.new_cate_2_nm,
        a.new_cate_3_nm,
        a.sku_cate_nm,
        a.layer_nm,
        a.onsale_flag,
        a.img_url,
        reference_tp
    FROM prod.skc_master a
    INNER JOIN temp.priority_list p0
        ON a.skc = p0.skc
),

sales AS (
    SELECT
        dt,
        a.skc,
        SUM(goods_cnt) AS goods_cnt,
        SUM(expose_uv2) AS expose_uv
    FROM prod.sales_daily a
    INNER JOIN skc_list b
        ON a.skc = b.skc
    WHERE dt >= '20250701'
    GROUP BY dt, skc
)
--main code: returns sales volume and exposure 7 days before and after association made
SELECT
    a0.*,
    a.association_dt,
    d.disassociation_dt,
    before.sales_7days_goods_cnt AS sales_7days_goods_cnt_bfr,
    before.sales_7days_expose_uv AS sales_7days_expose_uv_bfr,
    after.sales_7days_goods_cnt AS sales_7days_goods_aft,
    after.sales_7days_expose_uv AS sales_7days_expose_uv_aft

FROM skc_list a0

LEFT JOIN association_dt a
    ON a.skc = a0.skc

LEFT JOIN disassociation_dt d
    ON a0.skc = d.skc

LEFT JOIN (
    SELECT
        s1.skc,
        SUM(s1.goods_cnt) AS sales_7days_goods_cnt,
        SUM(s1.expose_uv) AS sales_7days_expose_uv
    FROM sales s1
    INNER JOIN association_dt a
        ON s1.skc = a.skc
    WHERE s1.dt BETWEEN
        date_format(
            date_add('day', -7, parse_datetime(a.association_dt, 'yyyyMMdd')),
            '%Y%m%d'
        )
        AND date_format(
            date_add('day', -1, parse_datetime(a.association_dt, 'yyyyMMdd')),
            '%Y%m%d'
        )
    GROUP BY s1.skc
) before 
    ON before.skc = a0.skc

LEFT JOIN (
    SELECT
        s2.skc,
        SUM(s2.goods_cnt) AS sales_7days_goods_cnt,
        SUM(s2.expose_uv) AS sales_7days_expose_uv
    FROM sales s2
    INNER JOIN association_dt a
        ON s2.skc = a.skc
    WHERE s2.dt BETWEEN
        a.association_dt
        AND date_format(
            date_add('day', 6, parse_datetime(a.association_dt, 'yyyyMMdd')),
            '%Y%m%d'
        )
    GROUP BY s2.skc
) after 
    ON after.skc = a0.skc;
