from django.contrib import admin
from django.urls import path
from app.views import *

urlpatterns = [
    path("allstore/", allstore),
    path('addstore/', addStore),
    path('addorder/', addOrder),
]