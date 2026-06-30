import React from "react";
import Button from "../../UI/Button/Button";
import classes from "./HeroSection.module.css";
import { Link } from "react-router-dom";

const heroSection = (props) => {
  return (
    <div>
      <div
        className={
          props.lightBg
            ? classes.HeroSection
            : [classes.HeroSection, classes.DarkBg].join(" ")
        }
      >
        <div className={classes.Container}>
          <div
            className={
              props.imgStart === "start"
                ? [classes.Row, classes.HeroRow, classes.Reverse].join(" ")
                : [classes.Row, classes.HeroRow].join(" ")
            }
          >
            <div className={classes.Col}>
              <div className={classes.HeroTextWrapper}>
                <div className={classes.TopLine}>{props.topLine}</div>
                <h1
                  className={
                    props.lightText
                      ? classes.Heading
                      : [classes.Heading, classes.Dark].join(" ")
                  }
                >
                  {props.headLine}
                </h1>
                <p
                  className={
                    props.lightTextDesc
                      ? classes.HeroSubtitle
                      : [classes.HeroSubtitle, classes.Dark].join(" ")
                  }
                >
                  {props.description}
                </p>
                <Link to={props.buttonLink}>
                  <Button
                    buttonSize={props.btnSize}
                    buttonColor={props.btnColor}
                    buttonStyle={props.btnStyle}
                  >
                    {props.buttonLabel}
                  </Button>
                </Link>
              </div>
            </div>
            <div className={classes.Col}>
              <div className={classes.HeroImgWrapper}>
                <img
                  src={props.src}
                  alt={props.alt}
                  className={classes.HeroImg}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default heroSection;
