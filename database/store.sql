INSERT INTO Prices (user_id, type_id, product_id, prices) VALUES
  (2, 1, NULL, '[[3, "CAD3000"], [2, "CAD2500"], [1, "CAD1500"] ]'::JSON),
  (2, 4, NULL, '[[3, "CAD1000"], [1, "CAD500"]]'::JSON),
  (2, 8, 200,  '[[1, "CAD50"]]'::JSON),
  (2, 5, NULL, '[[3, "CAD500"], [1, "CAD200"]]'::JSON),
  (2, 6, NULL, '[[3, "CAD500"], [1, "CAD200"]]'::JSON),
  (2, 7, NULL, '[[3, "CAD600"], [1, "CAD300"]]'::JSON),
  (3, 9, 202, '[[6, "CAD50"]]'::JSON),
  (3, 9, 203, '[[2, "CAD0"]]'::JSON);

-- price_id | user_id | user_con_id | type_id | product_id |         prices
-- ----------+---------+-------------+---------+------------+------------------------
--         1 |       2 |             |       1 |            | {{3,30},{2,25},{1,15}}
--         2 |       2 |             |       4 |            | {{3,10},{1,5}}
--         3 |       2 |             |       8 |        200 | {{1,0.5}}
--         4 |       2 |             |       5 |            | {{3,5},{1,2}}
--         5 |       2 |             |       6 |            | {{3,5},{1,2}}
--         6 |       2 |             |       7 |            | {{3,6},{1,3}}
--         7 |       3 |             |       9 |        202 | {{6,0.5}}
--         8 |       3 |             |       9 |        203 | {{2,0}}
