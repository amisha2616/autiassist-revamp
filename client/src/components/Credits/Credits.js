import React from 'react';
import classes from './Credits.module.css';

const credits = props => {

    return (
        <div className={classes.Credits}>
            <div className={classes.Wrapper}>
                <div className={classes.Header}>
                    Credits
                </div>
                <div className={classes.CreditsList}>
                    <ul>
                        <li className={classes.ListItem}>
                            Research on <a href="https://www.researchgate.net/publication/339210193_Autism_Expression_and_Understanding_of_Emotions_Literature_Review">Autism, Expression, and Understanding of Emotions: Literature Review</a>.
                        </li>
                        <li className={classes.ListItem}>
                            Research on <a href="https://www.sciencedaily.com/releases/2007/06/070622183516.htm">Computer Game Helps Autistic Children Recognize Emotions</a>.
                        </li>
                        <li className={classes.ListItem}>
                            Research on <a href="https://molecularautism.biomedcentral.com/articles/10.1186/s13229-016-0113-9">Basic and complex emotion recognition in children with autism: cross-cultural findings</a>.
                        </li>
                        <li className={classes.ListItem}>
                            Landing page GIFS obtained from <a href="https://dribbble.com/satvikchachra/collections/3441773-autemo">dribbble.com</a>
                        </li>
                        <li className={classes.ListItem}>
                            Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">flaticon.com</a>
                        </li >
                        <li className={classes.ListItem}>
                            Sound effects obtained from <a href="https://www.zapsplat.com">zasplat.com</a>
                        </li >
                        <li className={classes.ListItem}>
                            Stock videos by <a href="http://www.videezy.com">videezy.com</a>
                        </li>
                        <li className={classes.ListItem}>
                            SVGs obtained from <a href="http://undraw.co">undraw.co</a>
                        </li>
                    </ul>
                </div>
            </div>

        </div>
    )
}

export default credits;