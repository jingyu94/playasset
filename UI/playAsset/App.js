import React from 'react';
import { StyleSheet, Text, View, TextInput, Image, Button, TouchableOpacity } from 'react-native';

export default class App extends React.Component {
  render() {
    return (
      <View style={styles.page_wrap}>
        <View style={[styles.header_wrap, styles.bg_white, styles.bd_1, styles.dirRow, styles.verticalCenter]}>
            <Text style={[styles.ft_14]}>
                image
            </Text>
            <Text style={[styles.h1]}>
                PlayAsset
            </Text>
            <Image
                style={styles.menuBtn}
                source={require('playAsset/images/hamburgerBtn.png')} />
        </View>
        <View style={[styles.body_wrap]}>
            <View style={[styles.dirRow]}>
                <TextInput style={[styles.inputSearch]} />
                <Button style={[styles.btnSearch]} title='검색' />
            </View>
        </View>
        <View style={[styles.footer_wrap, styles.bg_gray]}>
            <TextInput/>
        </View>
      </View>
    );
  }
}
const styles = StyleSheet.create({
    page_wrap: {flex: 1, padding: 5},
    header_wrap: {flex: 1, padding: 5},
    body_wrap: {flex: 10, padding: 5},
    footer_wrap: {flex: 1, padding: 5},

    bg_gray: {backgroundColor: '#DDD'},
    bg_black: {backgroundColor: '#000'},

    bd_1: {
        borderBottomWith: 1
    },

    ft_10: {fontSize: 10},
    ft_11: {fontSize: 11},
    ft_12: {fontSize: 12},
    ft_13: {fontSize: 13},
    ft_14: {fontSize: 14},

    ft_white: {color: '#FFF'},

    dirRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        justifyContent: 'space-between',
    },

    menuBtn: {
        width: '10%',
        height: '100%',
    },

    verticalCenter: {
        alignItems: 'center'
    },

    inputSearch: {
        width: '85%',
        borderWidth: 1,
        paddingTop: 0,
        paddingBottom: 0,
        paddingLeft: 5,
        paddingRight: 5
    },

    btnSearch: {
        alignItems: 'center',
        backgroundColor: '#DDD',
        padding: 10
    },

    h1: { fontSize: 26, fontWeight: "800" },
});

//const styles = require('./css/searchView.css').member;