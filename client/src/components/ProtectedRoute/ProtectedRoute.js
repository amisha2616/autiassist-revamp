import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import { AuthContext } from '../../auth/AuthContext';

const ProtectedRoute = ({ component: Component, roles, ...rest }) => (
    <AuthContext.Consumer>
        {auth => (
            <Route
                {...rest}
                render={props => {
                    if (auth.loading) {
                        return <div style={{ paddingTop: '90px', textAlign: 'center' }}>Checking login...</div>;
                    }

                    if (!auth.user) {
                        return <Redirect to={{ pathname: '/login', state: { from: props.location } }} />;
                    }

                    if (roles && roles.length > 0 && !roles.includes(auth.user.role)) {
                        return <Redirect to="/dashboard" />;
                    }

                    return <Component {...props} />;
                }}
            />
        )}
    </AuthContext.Consumer>
);

export default ProtectedRoute;
