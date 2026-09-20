plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("quran_fonts")
    dynamicDelivery {
        deliveryType.set("fast-follow")
    }
}
