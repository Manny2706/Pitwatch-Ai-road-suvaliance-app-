import { createSlice } from "@reduxjs/toolkit";

const statSlice = createSlice({
    name:"stats",
    initialState:{
        pending:null,
        rejected:null,
        resolved:null,
        total:null,
        inProgress:null,
    },
    reducers:{
        setPending:(state, action) => {
            state.pending = action.payload;
        },
        setRejected:(state, action) => {
            state.rejected = action.payload;
        },
        setResolved:(state, action) => {
            state.resolved = action.payload;
        },
        setTotal:(state, action) => {
            state.total = action.payload;
        },
        setInProgress:(state, action) => {
            state.inProgress = action.payload;
        },
    }
});

export const {setPending, setRejected, setResolved, setTotal, setInProgress} = statSlice.actions;
export default statSlice.reducer;
export const statSliceReducer = statSlice.reducer;