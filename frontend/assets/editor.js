// editor.js
class EditorMethodChannel {
    constructor() {
        this.handlers = {
            'setText': this.setText.bind(this),
            'setImage': this.setImage.bind(this),
            'updateElement': this.updateElement.bind(this),
            'deleteElement': this.deleteElement.bind(this),
            'getState': this.getState.bind(this),
            'setBackground': this.setBackground.bind(this),
            'undo': this.undo.bind(this),
            'redo': this.redo.bind(this)
        };

        // History management
        this.history = [];
        this.historyIndex = -1;
        this.maxHistory = 50;
    }

    // Handle incoming messages from Flutter
    handleMessage(message) {
        const handler = this.handlers[message.type];
        if (handler) {
            return handler(message.data);
        }
        console.warn(`Unknown message type: ${message.type}`);
    }

    // Send message to Flutter
    sendToFlutter(type, data) {
        if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('flutterHandler', {
                type: type,
                data: data
            });
        }
    }

    // History management
    addToHistory(state) {
        this.historyIndex++;
        this.history = this.history.slice(0, this.historyIndex);
        this.history.push(JSON.stringify(state));
        if (this.history.length > this.maxHistory) {
            this.history.shift();
            this.historyIndex--;
        }
        this.sendToFlutter('historyChanged', {
            canUndo: this.historyIndex > 0,
            canRedo: this.historyIndex < this.history.length - 1
        });
    }

    // Handler implementations
    setText(data) {
        console.log(data);
        editor.addElement({
            type: 'text',
            id: Date.now().toString(),
            text: data.text,
            style: {
                fontSize: data.fontSize || 24,
                fontFamily: data.fontFamily || 'Arial',
                color: data.color || '#000000',
                bold: data.bold || false,
                italic: data.italic || false
            },
            position: {
                x: data.x || 100,
                y: data.y || 100,
                width: data.width,
                height: data.height,
                rotation: data.rotation || 0
            }
        });
        console.log(editor.elements);
        this.addToHistory(editor.getState());
    }

    setImage(data) {
        const img = new Image();
        img.onload = () => {
            editor.addElement({
                type: 'image',
                id: Date.now().toString(),
                url: data.url,
                image: img,
                position: {
                    x: data.x || 100,
                    y: data.y || 100,
                    width: data.width || img.width,
                    height: data.height || img.height,
                    rotation: data.rotation || 0
                }
            });
            this.addToHistory(editor.getState());
        };
        img.src = data.url;
    }

    updateElement(data) {
        const element = editor.getElementById(data.id);
        if (element) {
            Object.assign(element, data.properties);
            editor.render();
            this.addToHistory(editor.getState());
        }
    }

    deleteElement(data) {
        editor.removeElement(data.id);
        this.addToHistory(editor.getState());
    }

    getState() {
        const state = editor.getState();
        this.sendToFlutter('editorState', state);
        return state;
    }

    setBackground(data) {
        const img = new Image();
        img.onload = () => {
            editor.setBackground(img);
            this.addToHistory(editor.getState());
        };
        img.src = data.url;
    }

    undo() {
        if (this.historyIndex > 0) {
            this.historyIndex--;
            const state = JSON.parse(this.history[this.historyIndex]);
            editor.setState(state);
            this.sendToFlutter('historyChanged', {
                canUndo: this.historyIndex > 0,
                canRedo: true
            });
        }
    }

    redo() {
        if (this.historyIndex < this.history.length - 1) {
            this.historyIndex++;
            const state = JSON.parse(this.history[this.historyIndex]);
            editor.setState(state);
            this.sendToFlutter('historyChanged', {
                canUndo: true,
                canRedo: this.historyIndex < this.history.length - 1
            });
        }
    }
}