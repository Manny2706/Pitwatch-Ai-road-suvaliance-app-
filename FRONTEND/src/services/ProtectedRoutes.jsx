import { Navigate, Outlet } from "react-router-dom";

function ProtectedRoutes() {
    const accessToken = localStorage.getItem("accessToken");
    if(!accessToken){
        return <Navigate to="/" replace/>
    }
    
  return <Outlet/>
}

export default ProtectedRoutes
