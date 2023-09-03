import pymongo
from .setting_db import SettingDB

class Store:
    def __init__(self, name, address, phone, open_hours, close_hours):
        self.name = name
        self.address = address
        self.phone = phone
        self.open_hours = open_hours
        self.close_hours = close_hours
    def to_json(self):
        return {"name": self.name, "address": self.address, "phone": self.phone, "open_hours": self.open_hours, "close_hours": self.close_hours}
    def __str__(self):
        return f"Store: {self.name} Address: {self.address} Phone: {self.phone} Open Hours: {self.open_hours} Close Hours: {self.close_hours}"

class StoreDB:
    def __init__(self):
        self.conn = pymongo.MongoClient(SettingDB.host, SettingDB.port)
        self.db = self.conn.testdb
        self.collection = self.db.stores
    def to_json(self):
        return {"name": self.name, "address": self.address, "phone": self.phone, "open_hours": self.open_hours, "close_hours": self.close_hours}
    def insert_one(self, store):
        resp = self.collection.insert_one(store.to_json())
        return resp
    def find_one(self, name):
        return self.collection.find_one({"name": name})
    def find_all(self):
        return self.collection.find()
    def update_one(self, id, store):
        self.collection.update_one({"_id": id}, {"$set": store.to_json()})
    def delete_one(self, id):
        self.collection.delete_one({"_id": id})

