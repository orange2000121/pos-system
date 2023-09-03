import pymongo
from .setting_db import SettingDB
from datetime import datetime, timezone, timedelta
from bson.objectid import ObjectId

class Ordr:
    def __init__(self, total_price: float) -> None:
        self.total_price = total_price
    
    def to_json(self):
        return {"total_price": self.total_price, "created_at": datetime.now(tz=timezone(timedelta(hours=8)))}
    
class OrdrDB:
    # todo 增加店家id
    def __init__(self) -> None:
        self.conn = pymongo.MongoClient(SettingDB.host, SettingDB.port)
        self.db = self.conn.testdb
        self.collection = self.db.orders
    
    def insert_one(self, ordr: Ordr):
        result = self.collection.insert_one(ordr.to_json())
        return result.inserted_id
    
    def find_one(self, id):
        return self.collection.find_one({"_id": id})
    
    def find_all(self):
        return self.collection.find()
    
    def update_one(self, id, ordr: Ordr):
        self.collection.update_one({"_id": id}, {"$set": ordr.to_json()})
    
    def delete_one(self, id):
        self.collection.delete_one({"_id": id})
    
    def find_by_created_at(self, created_at):
        return self.collection.find({"created_at": created_at})
    