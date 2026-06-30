import React from 'react';
import Level from '../../../containers/Level/Level';

const API_URL = '/api/game-questions?level=1';
const LEVEL = 1;

const level1 = () => {
    return <Level level={LEVEL} url={API_URL} />;
}

export default level1;
