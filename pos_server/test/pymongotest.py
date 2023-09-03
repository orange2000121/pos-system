import datetime
import pymongo
from bson.objectid import ObjectId

class SettingDB:
    host = "localhost"
    port = 27017


class Sale:
    def __init__(self, order_id: ObjectId, name: str, price: float, remark: str, quantity: int) -> None:
        self.order_id = order_id
        self.name = name
        self.price = price
        self.remark = remark
        self.quantity = quantity

    def to_json(self):
        return {"order_id": self.order_id, "name": self.name, "price": self.price, "remark": self.remark, "quantity": self.quantity}


class SaleDB:
    def __init__(self) -> None:
        self.conn = pymongo.MongoClient(SettingDB.host, SettingDB.port)
        self.db = self.conn.testdb
        self.collection = self.db.sales

    def insert_one(self, sale: Sale):
        json = sale.to_json()
        json["created_at"] = datetime.datetime.now(tz=datetime.timezone(datetime.timedelta(hours=8)))
        self.collection.insert_one(json)

    def find_one(self, id):
        return self.collection.find_one({"_id": id})

    def find_all(self):
        return self.collection.find()

    def update_one(self, id, sale: Sale):
        self.collection.update_one({"_id": id}, {"$set": sale.to_json()})

    def delete_one(self, id):
        self.collection.delete_one({"_id": id})

    def delete_many(self, order_id):
        self.collection.delete_many({"order_id": order_id})

    def find_by_order_id(self, order_id):
        return self.collection.find({"order_id": order_id})

if __name__ == "__main__":
    sale = Sale(ObjectId("5f9b0b9b9b9b9b9b9b9b9b9b"), "Cafe sua da", 20000, "Khong duong", 2)
    db = SaleDB()
    db.insert_one(sale)