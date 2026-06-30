import React from "react";
import "./blog.css";
import { useState } from "react";

function Blog() {
  const [toggleCardClass1, setToggleCardClass1] = useState(false);
  const [toggleCardClass2, setToggleCardClass2] = useState(false);
  const [toggleCardClass3, setToggleCardClass3] = useState(false);
  const [toggleCardClass4, setToggleCardClass4] = useState(false);

  const question = ["What is Autism?", "Causes of Autism?","Treatments for Autism?"];

  // const answers = [
  //   "Autism spectrum disorder (ASD) is a complex developmental condition involving persistent challenges with social communication, restricted interests, and repetitive behavior. While autism is considered a lifelong disorder, the degree of impairment in functioning because of these challenges varies between individuals with autism.",
  //   "Children born to older parents are at a higher risk for having autism.Parents who have a child with ASD have a 2 to 18 percent chance of having a second child who is also affected.",
  // ];
  return (
    <div className="blogContainer">
      <div className="LevelScreen_Header">Blog</div>
      <div className="blogWrapper">
        {/* Card 1 */}
        <div className="container">
          {toggleCardClass1 ? (
            <div
              className="card"
              onClick={() => setToggleCardClass1(!toggleCardClass1)}
            >
              <div className="card__inner">
                <div className="card__face color__gradient">
                  <div className="card__content">
                    <div className="card__body">
                      {/* <h3>JavaScript Wizard</h3> */}
                      <p style={{fontSize:"1rem"}}>
                        {/* {answers[0]} */}
                        <ul style={{ paddingLeft: "12px"}}>
                          <li>
                            Autism spectrum disorder (ASD) is a developmental
                            disability caused by differences in the brain.{" "}
                          </li>
                          <br />
                          <li>
                          Some people with ASD have a known difference, such as a genetic condition. Other causes are not yet known. {" "}
                          </li>
                          {/* <br /> */}
                        </ul>
                        Statistics
                        <br />
                        <br />
                        <li>Boys are four times more likely to be diagnosed with autism than girls.</li>
                        <br />
                        <li>Autism affects all ethnic and socioeconomic groups.</li>
                        <br />
                       
                        {/* <li>1 in 27 boys identified with autism.</li>
                        <br />
                        <li>1 in 116 girls identified with autism</li>
                        <br /> */}
                    
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div
              className="card"
              onClick={() => setToggleCardClass1(!toggleCardClass1)}
            >
              <div className="card__inner">
                <div className="card__face">
                  <div className="card__content">
                    <div className="card__header">
                      <img src="https://grinchcreator.github.io/Austism-Spectrum/feature1.png" alt="" className="pp" />
                      {/* <h2>Tyler Potts</h2> */}
                    </div>
                    <div className="card__body" style={{display:"flex",justifyContent:"center"}}>
                      <h3>{question[0]}</h3>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
        {/* End of card 1 */}

        {/*card 2 */}
        <div className="container">
          {toggleCardClass2 ? (
            <div
              className="card"
              onClick={() => setToggleCardClass2(!toggleCardClass2)}
            >
              <div className="card__inner">
                <div className="card__face color__gradient">
                  <div className="card__content">
                    <div className="card__body">
                      <p style={{fontSize:"1rem"}}>
                        {/* {answers[1]} */}
                        <ul style={{ paddingLeft: "12px" }}>
                          <li>
                          The exact causes of ASD are not yet fully understood, but research suggests that genetic and environmental factors play a role.
                          </li>
                          <br />
                          <li>
                          Studies have found that certain genetic mutations and prenatal complications may increase the risk of developing ASD. Environmental factors such as exposure to toxins and infections during pregnancy may also be a contributing factor.
                          </li>
                          <br />
                          
                        </ul>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div
              className="card"
              onClick={() => setToggleCardClass2(!toggleCardClass2)}
            >
              <div className="card__inner">
                <div className="card__face" >
                  <div className="card__content">
                    <div className="card__header">
                      <img src="https://grinchcreator.github.io/Austism-Spectrum/feature2.png" alt="" className="pp" />
                    </div>
                    <div className="card__body" style={{display:"flex",justifyContent:"center"}}>
                      <h3>{question[1]}</h3>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* End of card 2 */}
        
        {/* Card 3 */}
        <div className="container">
          {toggleCardClass4 ? (
            <div
              className="card"
              onClick={() => setToggleCardClass4(!toggleCardClass4)}
            >
              <div className="card__inner"> 
                <div className="card__face color__gradient">
                  <div className="card__content">
                    <div className="card__body">
                      <p style={{fontSize:"1rem"}}>
                        {/* {answers[1]} */}
                        <ul style={{ paddingLeft: "12px" }}>
                        <li>The symptoms of ASD can vary greatly from person to person, but they generally fall into two categories: social communication and repetitive behaviors.</li>
                        <br />
                        <li>Social communication difficulties may include delayed speech, difficulty understanding social cues, lack of eye contact, and difficulty with conversation. Repetitive behaviors may include hand flapping, rocking, and obsessive interests or routines.</li>
                        <br />
                        </ul>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div
              className="card"
              onClick={() => setToggleCardClass4(!toggleCardClass4)}
            >
              <div className="card__inner">
                <div className="card__face" >
                  <div className="card__content">
                    <div className="card__header">
                      <img style={{objectFit:'contain'}} src="data:image/png;base64,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" alt="" className="pp" />
                    </div>
                    <div className="card__body" style={{display:"flex",justifyContent:"center"}}>
                      <h3>Signs and Symptoms?</h3>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* End of Card 3 */}

        {/* card 4 */}
        <div className="container">
          {toggleCardClass3 ? (
            <div
              className="card"
              onClick={() => setToggleCardClass3(!toggleCardClass3)}
            >
              <div className="card__inner">
                <div className="card__face color__gradient">
                  <div className="card__content">
                    <div className="card__body">
                      {/* <h3>JavaScript Wizard</h3> */}
                      <p style={{fontSize:"1rem"}}>
                      There is currently no treatment but people who have ASD have the best chance of using all of their abilities and skills if they receive appropriate therapies and interventions.
                      <ul style={{ paddingLeft: "12px" }}>
                      <li>Behavioral management therapy</li>
                      <li>Cognitive behavior therapy</li>
                      <li>Early intervention</li>
                      <li>Educational and school-based therapies</li>
                      <li>Joint attention therapy</li>
                      <li>Medication treatment</li>
                      <li>Nutritional therapy</li>
                      <li>Occupational therapy</li>
                      <li>Parent-mediated therapy</li>
                      <li>Physical therapy</li>
                      {/* <li>Social skills training</li>
                      <li>Speech-language therapy</li> */}
                        </ul>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div
              className="card"
              onClick={() => setToggleCardClass3(!toggleCardClass3)}
            >
              <div className="card__inner">
                <div className="card__face">
                  <div className="card__content">
                    <div className="card__header">
                      <img src="https://grinchcreator.github.io/Austism-Spectrum/feature3.png" alt="" className="pp" />
                      {/* <h2>Tyler Potts</h2> */}
                    </div>
                    <div className="card__body" style={{display:"flex",justifyContent:"center"}}>
                      <h3>{question[2]}</h3>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* End of Card 4 */}

        
      </div>

      
    </div>
  );
}

export default Blog;
