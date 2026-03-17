import Navbar from "./components/Navbar"
import Hero from "./components/Hero"
import Features from "./components/Features"
import SensorChart from "./components/Sensorchart"
import FarmerDashboard from "./components/FarmerDashboard"
import Team from "./components/Team"
import SolarZoom from "./components/SolarZoom"

function App(){

  return(
    <>
      <SolarZoom />
      <Navbar/>
      <Hero/>
      <Features/>
      <SensorChart/>
      <FarmerDashboard/>
      <Team/>
    </>
  )
}

export default App