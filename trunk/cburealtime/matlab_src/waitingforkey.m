function varargout = waitingforkey(varargin)
% WAITINGFORKEY MATLAB code for waitingforkey.fig
%      WAITINGFORKEY, by itself, creates a new WAITINGFORKEY or raises the existing
%      singleton*.
%
%      H = WAITINGFORKEY returns the handle to a new WAITINGFORKEY or the handle to
%      the existing singleton*.
%
%      WAITINGFORKEY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAITINGFORKEY.M with the given input arguments.
%
%      WAITINGFORKEY('Property','Value',...) creates a new WAITINGFORKEY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before waitingforkey_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to waitingforkey_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help waitingforkey

% Last Modified by GUIDE v2.5 17-Mar-2011 14:52:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @waitingforkey_OpeningFcn, ...
                   'gui_OutputFcn',  @waitingforkey_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before waitingforkey is made visible.
function waitingforkey_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to waitingforkey (see VARARGIN)

% Choose default command line output for waitingforkey
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes waitingforkey wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = waitingforkey_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
