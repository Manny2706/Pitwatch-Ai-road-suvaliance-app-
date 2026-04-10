import { createSlice } from "@reduxjs/toolkit";

const dailyDataSlice = createSlice({
    name: "dailyData",
    initialState:{
        Sunday:null,
        Monday:null,
        Tuesday:null,
        Wednesday:null,
        Thursday:null,
        Friday:null,
        Saturday:null,    
    },
    reducers:{
        setSunday:(state, action) => {
            state.Sunday = action.payload;
        },
        setMonday:(state, action) => {
            state.Monday = action.payload;
        },
        setTuesday:(state, action) => {
            state.Tuesday = action.payload;
        },
        setWednesday:(state, action) => {
            state.Wednesday = action.payload;
        },
        setThursday:(state, action) => {
            state.Thursday = action.payload;
        },
        setFriday:(state, action) => {
            state.Friday = action.payload;
        },
        setSaturday:(state, action) => {
            state.Saturday = action.payload;
        },
    }
});

export const {setFriday, setMonday, setSaturday, setSunday, setThursday, setTuesday,setWednesday} = dailyDataSlice.actions;
export default dailyDataSlice.reducer;
export const dailyDataSliceReducer = dailyDataSlice.reducer;