import json
from django.shortcuts import render
from app.database.orders_db import Ordr, OrdrDB

from app.database.sales_db import Sale, SaleDB
from .database.store_db import *
from django.http import HttpResponse
# Create your views here.

def allstore(request):
    allstore = StoreDB().find_all()
    return HttpResponse(allstore)
def addStore(request):
    store_name = request.GET.get('store_name')
    store_address = request.GET.get('store_address')
    store_phone = request.GET.get('store_phone')
    store = Store(store_name, store_address, store_phone, "8:00", "22:00")
    resp = StoreDB().insert_one(store)
    return HttpResponse(resp)

def addOrder(request):
    sale_db = SaleDB()
    order_db = OrdrDB()
    if(request.method == "GET"):
        total_price = request.GET.get('total_price')
        order_id = order_db.insert_one(Ordr(total_price))
        data = request.body
        json_data = json.loads(data)
        for item in json_data:
            try:
                sale_db.insert_one(Sale(order_id, item["name"], item["price"], item["remark"], item["quantity"]))
            except Exception as e:
                return HttpResponse(e)
        return HttpResponse("Success")
    else:
        return HttpResponse("should be POST")