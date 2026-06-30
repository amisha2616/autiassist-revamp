import React, { Component } from "react";
import LevelButton from "../UI/Button/LevelButton/LevelButton";
import LevelNoButton from "../UI/Button/LevelNoButton/LevelNoButton";
import FooterSection from "../FooterSection/FooterSection";
// import ImageIcon from "../../assets/icons/picture.svg";
import AudioIcon from "../../assets/icons/aupio.png";
// import VideoIcon from "../../assets/icons/youtube.svg";
import { Link } from "react-router-dom";
import classes from "./LevelScreen.module.css";

class LevelScreen extends Component {
  render() {
    return (
      <div className="App" style={{ height: "100%" }}>
        <main className={classes.PageContent}>
          <div className={classes.LevelScreen_Header}>GAMIFY</div>

          <div className={classes.LevelScreen_Container}>
            {/* <Link to="/question&answer">
              <LevelButton>
                <img style={{height:'11.5rem', width:'11.5rem'}} src="https://icon-library.com/images/question-answer-icon/question-answer-icon-14.jpg" alt="Level-0 Icon" />
              </LevelButton>
            </Link> */}
            <Link to="/level1">
              <LevelButton>
                <div className={classes.circle_green}>
                  <img className="circle-image" style={{ height: '7rem', marginTop: '1.8rem' }} src="https://icon-library.com/images/136524.svg.svg" alt="Level-1 Icon" />
                </div>
              </LevelButton>
            </Link>

            <Link to="/level2">
              <LevelButton>
                <img style={{ height: '11.5rem', width: '11.5rem' }} src={AudioIcon} alt="Level-2 Icon" />
              </LevelButton>
            </Link>

            <Link to="/level3">
              <LevelButton>
                <img style={{ height: '14rem', width: '22rem' }} src="https://icon-library.com/images/video-icon-flat/video-icon-flat-26.jpg" alt="Level-3 Icon" />
              </LevelButton>
            </Link>

          </div>

          <div className={classes.LevelBtns_Container}>
            {/* <Link to="/level0">
              <LevelNoButton>Questionarrie</LevelNoButton>
            </Link> */}
            {/* <Link to="/question&answer">
              <LevelNoButton>Q&A</LevelNoButton>
            </Link> */}
            <Link to="/level1">
              <LevelNoButton>Images</LevelNoButton>
            </Link>
            <Link to="/level2">
              <LevelNoButton>Audio</LevelNoButton>
            </Link>
            <Link to="/level3">
              <LevelNoButton>Videos</LevelNoButton>
            </Link>
          </div>
        </main>
        <FooterSection />
      </div>
    );
  }
}

export default LevelScreen;
