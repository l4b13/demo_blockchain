import flask
import json

app = flask.Flask(__name__)
app.config['SECRET_KEY'] = 'Ethereum'

with open('users.json','r', encoding='utf-8') as f:
    users = json.load(f)

@app.route('/', methods=['GET','POST'])
def index():
    if flask.request.method == 'POST':
        l = flask.request.form['login']
        p = flask.request.form['pwd']
        if l in users and users[l]['pwd'] == p:
            flask.session['username'] = l
        else:
            return flask.render_template('index.html', error='Логин или пароль неверен!')
   
    if 'username' in flask.session:
        if users[flask.session['username']]['role'] == 1:
            return flask.render_template('seller.html', user=users[flask.session['username']])
        else:
            return flask.render_template('customer.html', user=users[flask.session['username']])
   
    return flask.render_template('index.html')

@app.route('/logout')
def logout():
    flask.session.pop('username')
    return flask.redirect(flask.url_for('index'))

@app.route('/profile')
def profile():
    if 'username' not in flask.session:
        return flask.redirect(flask.url_for('index'))
    login = flask.session['username']
    user = users[login]
    if user['role'] == 1:
        return flask.render_template('seller_p.html', user=user, login=login)
    return flask.render_template('customer_p.html', user=user, login=login)

@app.route('/change_role')
def change_role():
    if 'username' not in flask.session:
        return flask.redirect(flask.url_for('index'))
    login = flask.session['username']
    user = users[login]
    if user['role'] == 0 and user['employee']:
        user['role'] = 1
    elif user['role'] == 1 and user['employee']:
        user['role'] = 0
    return flask.redirect(flask.url_for('index'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if flask.request.method == 'POST':
        #add new user
        user={"fio": flask.request.form['name'],
              "account": flask.request.form['account'],
              "employee": False,
              "role": 0,
              "pwd": flask.request.form['pwd']
              }
        users[flask.request.form['login']] = user
        #login user
        flask.session['username'] = flask.request.form['login']
        #save users to json file
        with open('users.json', 'w', encoding='utf-8') as f:
            json.dump(users, f)
        return flask.redirect(flask.url_for('index'))
    return flask.render_template('register.html')