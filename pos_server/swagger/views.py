from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from rest_framework.decorators import action
from rest_framework.response import Response
 
 
class AddGoods():
    """
    添加商品
    """
 
    request_body = openapi.Schema(type=openapi.TYPE_OBJECT,
                                  required=['sku_name', 'price', 'count', 'selling_price','count','stock','instruction','title'], properties=
                                  {'sku_name': openapi.Schema(type=openapi.TYPE_STRING, description='商品名称'),
                                   'price': openapi.Schema(type=openapi.TYPE_STRING, description='商品价格'),
                                   'count': openapi.Schema(type=openapi.TYPE_STRING, description='商品数量'),
                                   'stock': openapi.Schema(type=openapi.TYPE_STRING, description='商品库存'),
                                   'instruction': openapi.Schema(type=openapi.TYPE_STRING, description='商品数量'),
                                   'title': openapi.Schema(type=openapi.TYPE_STRING, description='商品数量')}
                                  )
 
    @swagger_auto_schema(method='post', request_body=request_body, )
    @action(methods=['post'], detail=False, )
    def post(self, request):
        return Response({'msg': '商品添加成功', 'code': 200})