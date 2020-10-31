class StoreService{
  Function() refreshZoomImage;
  static final StoreService _storeSingleton = new StoreService._internal();
  factory StoreService() {
    return _storeSingleton;
  }
  StoreService._internal();

}


StoreService Store=new StoreService();

