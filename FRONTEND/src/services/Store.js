import { configureStore } from "@reduxjs/toolkit";
import statReducer from "./statSlice";
import dailyDataReducer from "./dailyDataSlice";
const Store = configureStore({
    reducer:{
        stat : statReducer,
        dailyData : dailyDataReducer
    }
})

export default Store;