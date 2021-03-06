# vi:filetype=
use OpenResty::Config;
my $reason;
BEGIN {
    OpenResty::Config->init;
    if ($OpenResty::Config{'backend.type'} eq 'PgMocked' ||
        $OpenResty::Config{'backend.recording'}) {
        $reason = 'Skipped in PgMocked or recording mode here.';
    }
    #undef $reason;
}
use t::OpenResty $reason ? (skip_all => $reason) : ();

plan tests => 3 * blocks();

run_tests;

__DATA__

=== TEST 1: UTF-8
--- charset: UTF-8
--- request
DELETE /=/model?_user=$TestAccount&_password=$TestPass&_use_cookie=1
--- response
{"success":1}



=== TEST 2: GBK
--- charset: GBK
--- request
DELETE /=/model?_charset=GBK
--- response
{"success":1}



=== TEST 3: Create a model in GBK
--- charset: GBK
--- request
POST /=/model/Foo?_charset=GBK
{ 
    "description": "你好么？", 
    "columns": [
        {"name":"bar","type":"text","label":"嘿嘿"}
    ] 
}
--- response
{"success":1}



=== TEST 4: Check the data in GB2312
--- charset: GB2312
--- request
GET /=/model/Foo?_charset=GB2312
--- response
{
    "columns":[
        {"name":"id","label":"ID","type":"serial"},
        {"unique":false,"not_null":false,"name":"bar","default":null,"label":"嘿嘿","type":"text"}
    ],
    "name":"Foo",
    "description":"你好么？"
}



=== TEST 5: Check the data in utf8
--- charset: utf8
--- request
GET /=/model/Foo?_charset=utf8
--- response
{"columns":[
    {"name":"id","label":"ID","type":"serial"},
    {"name":"bar","default":null,"label":"嘿嘿","type":"text","unique":false,"not_null":false}
    ],
    "name":"Foo","description":"你好么？"}



=== TEST 6: Check the data in big5
--- charset: big5
--- request
GET /=/model/Foo?_charset=big5
--- response
{
    "columns":[
        {"name":"id","label":"ID","type":"serial"},
        {"unique":false,"not_null":false,"name":"bar","default":null,"label":"嘿嘿","type":"text"}
    ],
    "name":"Foo",
    "description":"你好么？"
}



=== TEST 7: Check the data in latin1
--- charset: latin-1
--- request
GET /=/model/Foo/bar?_charset=latin-1
--- response
{"name":"bar","default":null,"label":"??","type":"text","unique":false,"not_null":false}



=== TEST 8: Insert records in Big5
--- charset: Big5
--- request
POST /=/model/Foo/~/~?_charset=Big5
{ "bar": "廣告服務" }
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/Foo/id/1"}



=== TEST 9: Check the record
--- request
GET /=/model/Foo/~/~
--- response
[{"bar":"廣告服務","id":"1"}]



=== TEST 10: Check the record (in YAML)
--- request
GET /=/model/Foo/~/~.yml
--- format: YAML
--- response
--- 
- 
  bar: 廣告服務
  id: 1



=== TEST 11: Insert records in Big5
--- charset: Big5
--- request
GET /=/model/Foo/~/~?_charset=Big5
--- response
[{"bar":"廣告服務","id":"1"}]



=== TEST 12: Create a model in UTF-8
--- charset: UTF-8
--- request
POST /=/model/Utf8?_charset=guessing
{ "description": "文字编码测试utf8",
    "columns": [{"name":"bar","type":"text", "label":"我们的open api"}] }
--- response
{"success":1}



=== TEST 13: Check the data in UTF-8
--- charset: UTF-8
--- request
GET /=/model/Utf8?_charset=UTF-8
--- response
{
  "columns":[
    {"name":"id","label":"ID","type":"serial"},
    {"name":"bar","default":null,"label":"我们的open api","type":"text","unique":false,"not_null":false}
  ],
  "name":"Utf8",
  "description":"文字编码测试utf8"
}



=== TEST 14: Create a model in GBK
--- charset: GBK
--- request
POST /=/model/Gbk?_charset=guessing
{ "description": "文字编码测试GBK 张皛珏 万珣新",
    "columns": [{"name":"bar","type":"text", "label":"我们的open api"}] }
--- response
{"success":1}



=== TEST 15: Check the data in UTF-8
--- charset: UTF-8
--- request
GET /=/model/Gbk?_charset=UTF-8
--- response
{
  "columns":[
    {"name":"id","label":"ID","type":"serial"},
    {"name":"bar","default":null,"label":"我们的open api","type":"text","unique":false,"not_null":false}
  ],
  "name":"Gbk",
  "description":"文字编码测试GBK 张皛珏 万珣新"
}



=== TEST 16: Create a model in GB2312
--- charset: GB2312
--- request
POST /=/model/Gb2312?_charset=guessing
{ "description": "文字编码测试GB2312",
    "columns": [{"name":"bar","type":"text","label":"我们的open api"}] }
--- response
{"success":1}



=== TEST 17: Check the data in UTF-8
--- charset: UTF-8
--- request
GET /=/model/Gb2312?_charset=UTF-8
--- response
{
  "columns":[
    {"name":"id","label":"ID","type":"serial"},
    {"name":"bar","default":null,"label":"我们的open api","type":"text","unique":false,"not_null":false}
  ],
  "name":"Gb2312",
  "description":"文字编码测试GB2312"
}



=== TEST 18: Create a model in big5
--- charset: Big5
--- request
POST /=/model/Big5?_charset=guessing
{ "description": "文字編碼測試big5", "columns":
    [{"name":"bar","type":"text","label":"我們的open api"}] }
--- response
{"success":1}



=== TEST 19: Check the data in UTF-8
--- charset: UTF-8
--- request
GET /=/model/Big5?_charset=UTF-8
--- response
{
  "columns":[
    {"name":"id","label":"ID","type":"serial"},
    {"name":"bar","default":null,"label":"我們的open api","type":"text","unique":false,"not_null":false}
  ],
  "name":"Big5",
  "description":"文字編碼測試big5"
}



=== TEST 20: POST utf-8 chars
--- charset: UTF-8
--- request
POST /=/model/Big5/~/~
{"bar":"你好么？"}
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/Big5/id/1"}



=== TEST 21: Get the row
--- request
GET /=/model/Big5/id/1
--- response
[{"bar":"你好么？","id":"1"}]



=== TEST 22: logout
--- request
GET /=/logout
--- response
{"success":1}

