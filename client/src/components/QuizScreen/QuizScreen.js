import React, { Component } from "react";
import LevelButton from "../UI/Button/LevelButton/LevelButton";
import LevelNoButton from "../UI/Button/LevelNoButton/LevelNoButton";
import FooterSection from "../FooterSection/FooterSection";
// import ImageIcon from "../../assets/icons/picture.svg";
//import AudioIcon from "../../assets/icons/aupio.png";
// import VideoIcon from "../../assets/icons/youtube.svg";
import { Link } from "react-router-dom";
import classes from "./QuizScreen.module.css";

class LevelScreen extends Component {
  render() {
    return (
      <div className="App" style={{ height: "100%" }}>
        <main className={classes.PageContent}>
          <div className={classes.LevelScreen_Header}>ASSESSMENT</div>

          <div className={classes.LevelScreen_Container}>
            <Link to="/question&answer">
              <LevelButton>
                <div className={classes.circle_green}>
                  <img className="circle-image" style={{ height: '11rem', marginTop: '0.8rem' }} src="https://cdn3.iconfinder.com/data/icons/family-member-flat-happy-family-day/512/Brother-512.png" alt="Level-1 Icon" />
                </div>
              </LevelButton>
            </Link>

            <Link to="/question&answeradult">
              <LevelButton>
                {/* <div className={classes.circle_green}> */}
                {/* <img style={{height:'9.3rem',width:'10rem'}} src="https://cdn-icons-png.flaticon.com/512/6812/6812973.png" alt="Level-2 Icon" /> */}
                <img style={{ height: '11.5rem', width: '11.5rem' }} src="https://cdn4.iconfinder.com/data/icons/avatar-circle-1-1/72/53-256.png" alt="Level-2 Icon" />
                {/* </div> */}
              </LevelButton>
            </Link>
          </div>

          <div className={classes.LevelBtns_Container}>
            <Link to="/question&answer">
              <LevelNoButton>Child Quiz</LevelNoButton>
            </Link>
            <Link to="/question&answeradult">
              <LevelNoButton>Adult Quiz</LevelNoButton>
            </Link>
          </div>
        </main>
        <FooterSection />
      </div>
    );
  }
}

export default LevelScreen;
