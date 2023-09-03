import pymongo
from .setting_db import SettingDB


class Staff:
    def __init__(self, name, phone, birthday):
        self.name = name
        self.phone = phone
        self.birthday = birthday
    def to_json(self):
        return {"name": self.name, "phone": self.phone, "birthday": self.birthday}

class StaffDB:
    def __init__(self):
        self.conn = pymongo.MongoClient(SettingDB.host, SettingDB.port)
        self.db = self.conn.testdb
        self.collection = self.db.staffs

    def find_one(self, id):
        return self.collection.find_one({"_id": id})

    def find_all(self):
        return self.collection.find()

    def insert_one(self, staff):
        self.collection.insert_one(staff)

    def update_one(self, id, staff):
        self.collection.update_one({"_id": id}, {"$set": staff})

    def delete_one(self, id):
        self.collection.delete_one({"_id": id})
