#include "DXWrapper.h"

DXWrapper::DXWrapper(HWND window, int width, int height)
{
	const DXGI_SWAP_CHAIN_DESC sd = { { width, height, { 60, 1 }, DXGI_FORMAT_R8G8B8A8_UNORM, DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED, DXGI_MODE_SCALING_UNSPECIFIED }, { 1, 0 }, DXGI_USAGE_RENDER_TARGET_OUTPUT, 1, NULL, TRUE, DXGI_SWAP_EFFECT_SEQUENTIAL, 0 };

	DXGI_SWAP_CHAIN_DESC temp;
	temp = sd;
	temp.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT | DXGI_USAGE_UNORDERED_ACCESS | DXGI_USAGE_SHADER_INPUT;
	temp.OutputWindow = window;


	D3D11CreateDeviceAndSwapChain(
		NULL,
		D3D_DRIVER_TYPE_HARDWARE,
		NULL,
		D3D11_CREATE_DEVICE_DEBUG,
		NULL,
		0,
		D3D11_SDK_VERSION,
		&temp,
		&(this->swapChain),
		&(this->device),
		NULL,
		&(this->context)
	);
	
}


DXWrapper::~DXWrapper()
{
	this->context->ClearState();
	this->device->Release();
	this->swapChain->Release();
}

void DXWrapper::present() {
	this->swapChain->Present(0, 0);
}

DXTexture DXWrapper::getTexture(int id) {
	return DXTexture(this->swapChain, this->device, id);
}

DXStructuredBuffer DXWrapper::getStructuredBuffer(unsigned int stride, unsigned int num) {
	return DXStructuredBuffer(this->device, stride, num);
}

DXShader DXWrapper::getComputeShader(const BYTE* bytecode) {
	return DXShader(device, bytecode);
}
