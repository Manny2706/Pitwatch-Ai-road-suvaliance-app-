import { Route, Routes } from "react-router-dom";
import LoginPage from "./pages/LoginPage";
import { Toaster } from "react-hot-toast";
import ProtectedRoutes from "./services/ProtectedRoutes";
import ReportsPage from "./pages/ReportsPage";
import DashBoardPage from "./pages/DashBoardPage";
import LiveMap from "./pages/LiveMap";

function App() {
  return (
    <div>
      <Toaster position="top-right" reverseOrder={false}/>
        <Routes>
          {/* Public routes */}
          <Route path="/" element={<LoginPage/>}></Route>
            
          {/* Protected routes */}
          <Route element={<ProtectedRoutes/>}>
          <Route path="/dashboard" element={<DashBoardPage/>}></Route>
          <Route path="/reports" element={<ReportsPage/>}></Route>
          <Route path="/livemap" element={<LiveMap/>}></Route>
          </Route>
        </Routes>
      
    </div>
  )
}

export default App
