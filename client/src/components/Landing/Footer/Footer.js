import React from 'react';
import classes from './Footer.module.css';
// import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
// import { faCoffee } from '@fortawesome/free-solid-svg-icons';
// import { githubProfile, twitterProfile, linkedinProfile } from './Data/Data';

// const importedProfiles = [githubProfile, linkedinProfile, twitterProfile];

// const profilesMap = importedProfiles.map(importedProfile => (
//     <a href={importedProfile.link} key={importedProfile.id}>
//         <FontAwesomeIcon className={classes.SocialIcons} icon={importedProfile.logo} size="2x" />
//     </a>
// ));

const footer = props => <div className={classes.Footer}>
    <div className={classes.FooterWrapper}>
        <div className={classes.TextWrapper}>
            Autism Spectrum Disorder
        </div>
        {

        }
        {/* <div className={classes.IconsWrapper}>
            {profilesMap}
        </div> */}
    </div>
</div>;

export default footer;