# vi:filetype=

use t::OpenResty;

plan tests => 3 * blocks();

run_tests;

__DATA__

=== TEST 1: Delete existing models
--- request
DELETE /=/model?_user=$TestAccount&_password=$TestPass&_use_cookie=1
--- response
{"success":1}



=== TEST 2: create a model
--- request
POST /=/model/account
{ "description": "test model","columns": [{ "name":"A","type":"text","label":"A" }]}
--- response
{"success":1}



=== TEST 3: Add a new column
--- request
POST /=/model/account/B
{"type":"integer","label":"b"}
--- response
{"success":1,"src":"/=/model/account/B"}



=== TEST 4: Check the new column
--- request
GET /=/model/account/B
--- response
{"name":"B","default":null,"label":"b","type":"integer","not_null",false}



=== TEST 5: Insert a record
--- request
POST /=/model/account/~/~
{ "A": "jingjing1"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/account/id/1"}



=== TEST 6: Add a new column not null is false
--- request
POST /=/model/account/C
{"type":"integer","label":"c","not_null":false}
--- response
{"success":1,"src":"/=/model/account/C"}



=== TEST 7: Check the new column C
--- request
GET /=/model/account/C
--- response
{"name":"C","default":null,"label":"c","type":"integer","not_null",false}



=== TEST 8: Insert a record
--- request
POST /=/model/account/~/~
{ "A": "jingjing2"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/account/id/2"}



=== TEST 9: Add a new column not null is true
--- request
POST /=/model/account/D
{"type":"integer","label":"d","not_null":true}
--- response
{"success":1,"src":"/=/model/account/D"}



=== TEST 10: Check the new column D
--- request
GET /=/model/account/D
--- response
{"name":"D","default":null,"label":"d","type":"integer","not_null",true}



=== TEST 11: Insert a record with value of D is null
--- request
POST /=/model/account/~/~
{ "A": "jingjing3"}
--- response
{"success":0,"error":"Not null constraint violated"} 



=== TEST 12: Insert a record with value of D is not null
--- request
POST /=/model/account/~/~
{ "A": "jingjing3","D":"1"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/account/id/3"}



=== TEST 13: alter C 
--- request
PUT /=/model/account/C
{"type":"integer","label":"c","not_null":true}
--- response
{"success":1,"src":"/=/model/account/C"}



=== TEST 14: Check the  column C
--- request
GET /=/model/account/C
--- response
{"name":"C","default":null,"label":"c","type":"integer","not_null",true}



=== TEST 15: Insert a record with value of C is not null
--- request
POST /=/model/account/~/~
{ "A": "jingjing4","C":"1","D":"2"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/account/id/4"}



=== TEST 16: Insert a record with value of C is not null
--- request
POST /=/model/account/~/~
{ "A": "jingjing4","D":"2"}
--- response
{"success":0,"error":"Not null constraint violated"} 



=== TEST 17: alter D
--- request
PUT /=/model/account/D
{"type":"integer","label":"c","not_null":false}
--- response
{"success":1,"src":"/=/model/account/D"}



=== TEST 18: Check the  column D
--- request
GET /=/model/account/D
--- response
{"name":"D","default":null,"label":"d","type":"integer","not_null",false}



=== TEST 19: Insert a record with value of D is null
--- request
POST /=/model/account/~/~
{ "A": "jingjing4","C":"3"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/account/id/5"}







